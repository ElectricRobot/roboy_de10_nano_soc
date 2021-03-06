// MyoControl 
// This module handles the communication and implements PID controller for each myo motor board.
// Communication with the motors is via SPI. The module is accessible via lightweight axi bridge.
// On axi read/write request, the upper 8 bit of the address define which value is accessed, while
// the lower 8 bit define for which motor (if applicable).
// Through the axi bridge, the following values can be READ
//	address            -----   [type] value
// [8'h00 8'h(motor)]         [int16] Kp - gain of PID controller
// [8'h01 8'h(motor)]         [int16] Ki - gain of PID controller
// [8'h02 8'h(motor)]         [int16] Kd - gain of PID controller
// [8'h03 8'h(motor)]         [int32] sp - setpoint of PID controller
// [8'h04 8'h(motor)]         [int16] forwardGain - gain of PID controller
// [8'h05 8'h(motor)]         [int16] outputPosMax - maximal output of PID controller
// [8'h06 8'h(motor)]         [int16] outputNegMax - minimal output of PID controller
// [8'h07 8'h(motor)]         [int16] IntegralPosMax - maximal integral of PID controller
// [8'h08 8'h(motor)]         [int16] IntegralNegMax - minimal integral of PID controller
// [8'h09 8'h(motor)]         [int16] deadBand - deadBand of PID controller
// [8'h0A 8'h(motor)]         [uint8] control_mode - control_mode of PID controller
// [8'h0B 8'h(motor)]         [int32] position - motor position
// [8'h0C 8'h(motor)]         [int16] velocity - motor velocity
// [8'h0D 8'h(motor)]         [int16] current - motor current
// [8'h0E 8'h(motor)]         [int16] displacement - spring displacement
// [8'h0F 8'h(motor)]         [int16] pwmRef - output of PID controller
// [8'h10 8'hz]               [uint32] update_frequency - update frequency between pid an motor board
// [8'h11 8'hz]               [uint32] power_sense_n - power sense pin
// [8'h12 8'hz]               [bool ]gpio_enable - gpio status
// [8'h13 8'h(motor)]         [uin16] angle - myo brick motor angle
// [8'h14 8'hz]               [uint32] myo_brick - myo_brick enable mask
// [8'h15 8'h(motor)]         [uint8] myo_brick_device_id - myo brick i2c device id
// [8'h16 8'h(motor)]         [int32] myo_brick_gear_box_ratio - myo brick gear box ratio
// [8'h17 8'h(motor)]         [int32] myo_brick_encoder_multiplier - myo brick encoder mulitiplier
// [8'h18 8'h(motor)]		   [int32] outputDivider- PID output divider
// [8'h19 8'h(motor)]		   [bool] i2c_ack_error - I2C ackowledge error (myoBrick angle sensor)
// [8'h1A 8'hz]		         [int32] elbow_joint_angle_error - setpoint error joint angle
// [8'h1B 8'hz]		         [int32] elbow_Kp_joint_angle - gain of joint angle PD controller
// [8'h1C 8'hz]		         [int32] elbow_Kd_joint_angle - gain of joint angle PD controller
// [8'h1D 8'hz]		         [int32] elbow_agonist - motor acting as agonist for elbow 1DOF joint
// [8'h1E 8'hz]		         [int32] elbow_antagonist - motor acting as antagonist for elbow 1DOF joint
// [8'h1F 8'hz]       		   [int32] elbow_joint_angle_setpoint - setpoint for elbow 1DOF joint
// [8'h20 8'hz]       		   [int32] elbow_joint_angle_device_id - joint_angle_device_id for elbow 1DOF joint
// [8'h21 8'hz]       		   [int32] elbow_joint_angle - current joint_angle of elbow 1DOF joint
// [8'h22 8'hz]       		   [int32] elbow_joint_angle_offset - joint_angle_offset for elbow 1DOF joint
// [8'h23 8'hz]       		   [int32] elbow_joint_control_result - joint_control_result for elbow 1DOF joint
// [8'h24 8'hz]       		   [int32] elbow_joint_pretension - joint_pretension for elbow 1DOF joint
// [8'h25 8'hz]       		   [int32] elbow_joint_deadband - joint_deadband for elbow 1DOF joint
// [8'h26 8'hz]       		   [bool]  hand_control - enables hand conrol
// [8'h27 8'h(board)]		   [int32] arm_board_device_id - i2c device for the respective board
// [8'h28 8'h(board)]         [uint8] motor0 - setpoint for motor0 of arm board
// [8'h29 8'h(board)]         [uint8] motor1 - setpoint for motor1 of arm board
// [8'h2A 8'h(board)]         [uint8] motor2 - setpoint for motor2 of arm board
// [8'h2B 8'h(board)]         [uint8] motor3 - setpoint for motor3 of arm board
// [8'h2C 8'h(board)]         [uint8] motor4 - setpoint for motor4 of arm board
// [8'h2D 8'hz]               [uint8] arm_board_ack_error - i2c ackowlege error for all four arm board 8'b00001111
// [8'h2E 8'hz]               [int32] elbow_smooth_distance - changes the nonlinear behaviour of the elbow agonist/antagonist muscles
// [8'h2F 8'hz]		         [int32] wrist_joint_angle_error - setpoint error joint angle
// [8'h30 8'hz]		         [int32] wrist_Kp_joint_angle - gain of joint angle PD controller
// [8'h31 8'hz]		         [int32] wrist_Kd_joint_angle - gain of joint angle PD controller
// [8'h32 8'hz]		         [int32] wrist_agonist - motor acting as agonist for wrist 1DOF joint
// [8'h33 8'hz]		         [int32] wrist_antagonist - motor acting as antagonist for wrist 1DOF joint
// [8'h34 8'hz]       		   [int32] wrist_joint_angle_setpoint - setpoint for wrist 1DOF joint
// [8'h35 8'hz]       		   [int32] wrist_joint_angle_device_id - joint_angle_device_id for wrist 1DOF joint
// [8'h36 8'hz]       		   [int32] wrist_joint_angle - current joint_angle of wrist 1DOF joint
// [8'h37 8'hz]       		   [int32] wrist_joint_angle_offset - joint_angle_offset for wrist 1DOF joint
// [8'h38 8'hz]       		   [int32] wrist_joint_control_result - joint_control_result for wrist 1DOF joint
// [8'h39 8'hz]       		   [int32] wrist_joint_pretension - joint_pretension for wrist 1DOF joint
// [8'h3A 8'hz]       		   [int32] wrist_joint_deadband - joint_deadband for wrist 1DOF joint
// [8'h3B 8'hz]               [int32] wrist_smooth_distance - changes the nonlinear behaviour of th wrist agonist/antagonist muscles
//
// Through the axi bridge, the following values can be WRITTEN
//	address            -----   [type] value
// [8'h00 8'h(motor)]         [int16] Kp - gain of PID controller
// [8'h01 8'h(motor)]         [int16] Ki - gain of PID controller
// [8'h02 8'h(motor)]         [int16] Kd - gain of PID controller
// [8'h03 8'h(motor)]         [int32] sp - setpoint of PID controller
// [8'h04 8'h(motor)]         [int16] forwardGain - gain of PID controller
// [8'h05 8'h(motor)]         [int16] outputPosMax - maximal output of PID controller
// [8'h06 8'h(motor)]         [int16] outputNegMax - minimal output of PID controller
// [8'h07 8'h(motor)]         [int16] IntegralPosMax - maximal integral of PID controller
// [8'h08 8'h(motor)]         [int16] IntegralNegMax - minimal integral of PID controller
// [8'h09 8'h(motor)]         [int16] deadBand - deadBand of PID controller
// [8'h0A 8'h(motor)]         [uint8] control_mode - control_mode of PID controller
// [8'h0B 8'hz]               [bool] reset_myo_control - reset
// [8'h0C 8'hz]               [bool] spi_activated - toggles spi communication
// [8'h0D 8'h(motor)]         [bool] reset_controller - resets individual PID controller
// [8'h0E 8'hz]               [bool] update_frequency - motor pid update frequency
// [8'h0F 8'hz]               [bool] gpio_enable - controls the gpio 
// [8'h10 8'hz]               [uint32] myo_brick - bit mask for indicating which muscle is a myoBrick
// [8'h11 8'h(motor)]         [uint8] myo_brick_device_id - i2c device id for reading the motor angle
// [8'h12 8'h(motor)]         [int32] myo_brick_gear_box_ratio - myo brick gear box ratio
// [8'h13 8'h(motor)]         [int32] myo_brick_encoder_multiplier - myo brick encoder mulitiplier
// [8'h14 8'h(motor)]         [int32] outputDivider- PID output divider
// [8'h15 8'hz]       		   [bool]  elbow_joint_control - enables joint conrol for 1DOF joint
// [8'h16 8'hz]       		   [int32] elbow_joint_angle_device_id - joint_angle_device_id for 1DOF joint
// [8'h17 8'h(motor)]		   [int32] elbow_agonist - motor acting as agonist for 1DOF joint
// [8'h18 8'h(motor)]		   [int32] elbow_antagonist - motor acting as antagonist for 1DOF join
// [8'h19 8'hz]		         [int32] elbow_Kp_joint_angle - gain of joint angle PD controller
// [8'h1A 8'hz]		         [int32] elbow_Kd_joint_angle - gain of joint angle PD controller
// [8'h1B 8'hz]       		   [int32] elbow_joint_angle_offset - joint_angle_offset for 1DOF joint
// [8'h1C 8'hz]       		   [int32] elbow_joint_pretension - joint_pretension for 1DOF joint
// [8'h1D 8'hz]       		   [int32] elbow_joint_deadband - joint_deadband for 1DOF joint
// [8'h1E 8'hz]		   		[int32] elbow_joint_angle_setpoint - setpoint for 1DOF joint
// [8'h1F 8'hz]       		   [bool]  hand_control - enables hand conrol
// [8'h20 8'h(board)]		   [int32] arm_board_device_id - i2c device for the respective board
// [8'h21 8'h(board)]         [uint8] motor0 - setpoint for motor0 of arm board
// [8'h22 8'h(board)]         [uint8] motor1 - setpoint for motor1 of arm board
// [8'h23 8'h(board)]         [uint8] motor2 - setpoint for motor2 of arm board
// [8'h24 8'h(board)]         [uint8] motor3 - setpoint for motor3 of arm board
// [8'h25 8'h(board)]         [uint8] motor4 - setpoint for motor4 of arm board
// [8'h26 8'hz]               [int32] elbow_smooth_distance - changes the nonlinear behaviour of th elbow agonist/antagonist muscles
// [8'h27 8'hz]       		   [bool]  wrist_joint_control - enables joint conrol for 1DOF joint
// [8'h28 8'hz]       		   [int32] wrist_joint_angle_device_id - joint_angle_device_id for 1DOF joint
// [8'h29 8'h(motor)]		   [int32] wrist_agonist - motor acting as agonist for 1DOF joint
// [8'h2A 8'h(motor)]		   [int32] wrist_antagonist - motor acting as antagonist for 1DOF join
// [8'h2B 8'hz]		         [int32] wrist_Kp_joint_angle - gain of joint angle PD controller
// [8'h2C 8'hz]		         [int32] wrist_Kd_joint_angle - gain of joint angle PD controller
// [8'h2F 8'hz]       		   [int32] wrist_joint_angle_offset - joint_angle_offset for 1DOF joint
// [8'h2R 8'hz]       		   [int32] wrist_joint_pretension - joint_pretension for 1DOF joint
// [8'h2F 8'hz]       		   [int32] wrist_joint_deadband - joint_deadband for 1DOF joint
// [8'h30 8'hz]		   		[int32] wrist_joint_angle_setpoint - setpoint for 1DOF joint
// [8'h31 8'hz]               [int32] wrist_smooth_distance - changes the nonlinear behaviour of th wrist agonist/antagonist muscles

// Features: 
// * use the NUMBER_OF_MOTORS parameter to define how many motors are connected on one SPI bus (maximum 254)
// * use the update_frequency to define at what rate the motors should be controlled
//   NOTE: The maximal update_frequency is limited by the amount of motors per SPI bus. For 7 motors
//			  on one bus this is for example ~2.8kHz. Setting a higher frequency has no effect.

//	BSD 3-Clause License
//
//	Copyright (c) 2018, Roboy
//	All rights reserved.
//
//	Redistribution and use in source and binary forms, with or without
//	modification, are permitted provided that the following conditions are met:
//
//	* Redistributions of source code must retain the above copyright notice, this
//	  list of conditions and the following disclaimer.
//
//	* Redistributions in binary form must reproduce the above copyright notice,
//	  this list of conditions and the following disclaimer in the documentation
//	  and/or other materials provided with the distribution.
//
//	* Neither the name of the copyright holder nor the names of its
//	  contributors may be used to endorse or promote products derived from
//	  this software without specific prior written permission.
//
//	THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
//	AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
//	IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
//	DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
//	FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
//	DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
//	SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
//	CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
//	OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
//	OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

// author: Simon Trendel, simon.trendel@tum.de, 2018

`timescale 1ns/10ps

module MYOControl (
	input clock,
	input reset,
	// this is for the avalon interface
	input [15:0] address,
	input write,
	input signed [31:0] writedata,
	input read,
	output signed [31:0] readdata,
	output waitrequest,
	// these are the spi ports
	output [NUMBER_OF_MOTORS-1:0] ss_n_o,
	input miso,
	output mosi,
	output sck,
	input mirrored_muscle_unit,
	input power_sense_n,
	output gpio_n,
	output myobrick_scl,
	inout myobrick_sda,
	output arm_scl,
	inout arm_sda
);

parameter NUMBER_OF_MOTORS = 6;
parameter CLOCK_SPEED_HZ = 50_000_000;
parameter ENABLE_MYOBRICK_CONTROL = 0;
parameter ENABLE_ARM_CONTROL = 0;

// gains and shit
// p gains
reg signed [15:0] Kp[NUMBER_OF_MOTORS-1:0];
// i gains
reg signed [15:0] Ki[NUMBER_OF_MOTORS-1:0];
// d gains
reg signed [15:0] Kd[NUMBER_OF_MOTORS-1:0];
// setpoints
reg signed [31:0] sp[NUMBER_OF_MOTORS-1:0];
// forward gains
reg signed [15:0] forwardGain[NUMBER_OF_MOTORS-1:0];
// output positive limits
reg signed [15:0] outputPosMax[NUMBER_OF_MOTORS-1:0];
// output negative limits
reg signed [15:0] outputNegMax[NUMBER_OF_MOTORS-1:0];
// integral negative limits
reg signed [15:0] IntegralNegMax[NUMBER_OF_MOTORS-1:0];
// integral positive limits
reg signed [15:0] IntegralPosMax[NUMBER_OF_MOTORS-1:0];
// deadband
reg signed [15:0] deadBand[NUMBER_OF_MOTORS-1:0];
// control mode
reg [1:0] control_mode[NUMBER_OF_MOTORS-1:0];
// reset pid_controller
reg reset_controller[NUMBER_OF_MOTORS-1:0];
// output divider
reg signed [31:0] outputDivider[NUMBER_OF_MOTORS-1:0];

// pwm output to motors 
wire signed [0:15] pwmRefs[NUMBER_OF_MOTORS-1:0];

// the following is stuff we receive from the motors via spi
// positions of the motors
reg signed [31:0] positions[NUMBER_OF_MOTORS-1:0];
// velocitys of the motors
reg signed [15:0] velocitys[NUMBER_OF_MOTORS-1:0];
// currents of the motors
reg signed [15:0] currents[NUMBER_OF_MOTORS-1:0];
// displacements of the springs
reg [15:0] displacements[NUMBER_OF_MOTORS-1:0];
reg [15:0] displacement_offsets[NUMBER_OF_MOTORS-1:0];

assign readdata = returnvalue;
assign waitrequest = (waitFlag && read) || update_controller;
reg [31:0] returnvalue;
reg waitFlag;

reg [31:0] update_frequency;
reg [31:0] actual_update_frequency;
reg [31:0] delay_counter;

// the following iterface handles read requests via lightweight axi bridge
// the upper 8 bit of the read address define which value we want to read
// the lower 8 bit of the read address define for which motor
always @(posedge clock, posedge reset) begin: AVALON_READ_INTERFACE
	if (reset == 1) begin
		waitFlag <= 1;
	end else begin
		waitFlag <= 1;
		if(read) begin
			case(address>>8)
				8'h00: returnvalue <= Kp[address[7:0]][15:0];
				8'h01: returnvalue <= Ki[address[7:0]][15:0];
				8'h02: returnvalue <= Kd[address[7:0]][15:0];
				8'h03: returnvalue <= sp[address[7:0]][31:0];
				8'h04: returnvalue <= forwardGain[address[7:0]][15:0];
				8'h05: returnvalue <= outputPosMax[address[7:0]][15:0];
				8'h06: returnvalue <= outputNegMax[address[7:0]][15:0];
				8'h07: returnvalue <= IntegralPosMax[address[7:0]][15:0];
				8'h08: returnvalue <= IntegralNegMax[address[7:0]][15:0];
				8'h09: returnvalue <= deadBand[address[7:0]][15:0];
				8'h0A: returnvalue <= control_mode[address[7:0]][1:0];
				8'h0B: returnvalue <= positions[address[7:0]][31:0];
				8'h0C: returnvalue <= velocitys[address[7:0]][15:0];
				8'h0D: returnvalue <= currents[address[7:0]][15:0];
				8'h0E: returnvalue <= displacements[address[7:0]][15:0];
				8'h0F: returnvalue <= pwmRefs[address[7:0]][0:15];
				8'h10: returnvalue <= actual_update_frequency;
				8'h11: returnvalue <= (power_sense_n==0); // active low
				8'h12: returnvalue <= gpio_enable;
				8'h13: returnvalue <= motor_angle[address[7:0]][31:0];
				8'h14: returnvalue <= myo_brick;
				8'h15: returnvalue <= myo_brick_device_id[address[7:0]][6:0];
				8'h16: returnvalue <= myo_brick_gear_box_ratio[address[7:0]][7:0];
				8'h17: returnvalue <= myo_brick_encoder_multiplier[address[7:0]][31:0];
				8'h18: returnvalue <= outputDivider[address[7:0]][31:0];
				8'h19: returnvalue <= myo_brick_ack_error[address[7:0]];
				8'h1A: returnvalue <= elbow_joint_angle_error[31:0];
				8'h1B: returnvalue <= elbow_Kp_joint_angle[31:0];
				8'h1C: returnvalue <= elbow_Kd_joint_angle[31:0];
				8'h1D: returnvalue <= elbow_agonist;
				8'h1E: returnvalue <= elbow_antagonist;
				8'h1F: returnvalue <= elbow_joint_angle_setpoint;
				8'h20: returnvalue <= elbow_joint_angle_device_id[6:0];
				8'h21: returnvalue <= elbow_joint_angle_curr[31:0];
				8'h22: returnvalue <= elbow_joint_angle_offset[31:0];
				8'h23: returnvalue <= elbow_joint_control_result[31:0];
				8'h24: returnvalue <= elbow_joint_pretension[31:0];
				8'h25: returnvalue <= elbow_joint_deadband[31:0];
				8'h26: returnvalue <= hand_control;
				8'h27: returnvalue <= arm_board_device_id[address[7:0]][6:0];
				8'h28: returnvalue <= motor0[address[7:0]];
				8'h29: returnvalue <= motor1[address[7:0]];
				8'h2A: returnvalue <= motor2[address[7:0]];
				8'h2B: returnvalue <= motor3[address[7:0]];
				8'h2C: returnvalue <= motor4[address[7:0]];
				8'h2D: returnvalue <= arm_board_ack_error;
				8'h2E: returnvalue <= elbow_smooth_distance[31:0];
				8'h2F: returnvalue <= wrist_joint_angle_error[31:0];
				8'h30: returnvalue <= wrist_Kp_joint_angle[31:0];
				8'h31: returnvalue <= wrist_Kd_joint_angle[31:0];
				8'h32: returnvalue <= wrist_agonist;
				8'h33: returnvalue <= wrist_antagonist;
				8'h34: returnvalue <= wrist_joint_angle_setpoint;
				8'h35: returnvalue <= wrist_joint_angle_device_id[6:0];
				8'h36: returnvalue <= wrist_joint_angle_curr[31:0];
				8'h37: returnvalue <= wrist_joint_angle_offset[31:0];
				8'h38: returnvalue <= wrist_joint_control_result[31:0];
				8'h39: returnvalue <= wrist_joint_pretension[31:0];
				8'h3A: returnvalue <= wrist_joint_deadband[31:0];
				8'h3B: returnvalue <= wrist_smooth_distance[31:0];
				default: returnvalue <= 32'hDEADBEEF;
			endcase
			if(waitFlag==1) begin // next clock cycle the returnvalue should be ready
				waitFlag <= 0;
			end
		end
	end
end
	
reg reset_myo_control;
reg spi_activated;
reg update_controller;
reg start_spi_transmission;
reg gpio_enable;
assign gpio_n = !gpio_enable;
	
reg [7:0] motor;
reg [7:0] pid_update;
reg [31:0] spi_enable_counter;
	
always @(posedge clock, posedge reset) begin: MYO_CONTROL_LOGIC
	reg spi_done_prev; 
	reg [7:0]i;
	reg [31:0] counter;
	reg spi_enable;
	if (reset == 1) begin
		reset_myo_control <= 0;
		spi_activated <= 0;
		motor <= 0;
		spi_done_prev <= 0;
		delay_counter <= 0;
		update_frequency <= 0;
		counter <= 0;
		spi_enable_counter <= 0;
		spi_enable <= 0;
		myo_brick <= 0;
		for(i=0; i<NUMBER_OF_MOTORS; i = i+1) begin : reset_reset_controller
			myo_brick_gear_box_ratio[i] <= 62;
			myo_brick_encoder_multiplier[i] <= 1;
			outputDivider[i] <= 1;
		end
		elbow_joint_control<=0;
		elbow_joint_angle_offset<=0;
		elbow_agonist <= NUMBER_OF_MOTORS;
		elbow_antagonist <= NUMBER_OF_MOTORS;
		elbow_smooth_distance <= 20;
	end else begin
		// toggle registers need to be set to zero at every clock cycle
		update_controller <= 0;
		start_spi_transmission <= 0;
		reset_myo_control <= 0;
		for(i=0; i<NUMBER_OF_MOTORS; i = i+1) begin : reset_reset_controller
			reset_controller[i] <= 0;
		end
		// for rising edge detection of spi done
		spi_done_prev <= spi_done;
		
		// increment counter, will be used to calculate actual update frequency
		counter <= counter + 1;
		
		// when spi is done, latch the received values for the current motor and toggle PID controller update of previous motor
		if(spi_done_prev==0 && spi_done) begin
			positions[motor][31:0] <= position[0:31];
			velocitys[motor][15:0] <= velocity[0:15];
			currents[motor][15:0] <= current[0:15];
			if(~myo_brick[motor]) begin
				if(mirrored_muscle_unit) begin 
					displacements[motor][15:0] <= (-1)*displacement[0:15]; 
				end else begin
					displacements[motor][15:0] <= displacement[0:15];
				end
			end else begin
				displacements[motor][15:0] <= motor_spring_angle[motor];
			end
			if(motor==0) begin // lazy update (we are updating the controller following the current spi transmission)
				pid_update <= NUMBER_OF_MOTORS-1; 
			end else begin
				pid_update <= motor-1;
			end
			update_controller <= 1; 
		end
		
		// if a frequency is requested, a delay counter makes sure the next motor cycle will be delayed accordingly
		if(update_frequency>0) begin
			if(spi_done_prev==0 && spi_done) begin
				if(motor<(NUMBER_OF_MOTORS-1)) begin
					motor <= motor + 1;
					start_spi_transmission <= 1;
					// apply joint control setpoints
					if(motor==elbow_agonist && elbow_joint_control) begin
						control_mode[motor] <= 2; // overwrite DISPLACEMENT control
						sp[motor] <= elbow_joint_angle_control_setpoint[0];
					end
					if(motor==elbow_antagonist && elbow_joint_control) begin
						control_mode[motor] <= 2; // overwrite DISPLACEMENT control
						sp[motor] <= elbow_joint_angle_control_setpoint[1];
					end
					// apply wrist joint control setpoints
					if(motor==wrist_agonist && wrist_joint_control) begin
						control_mode[motor] <= 2; // overwrite DISPLACEMENT control
						sp[motor] <= wrist_joint_angle_control_setpoint[0];
					end
					if(motor==wrist_antagonist && wrist_joint_control) begin
						control_mode[motor] <= 2; // overwrite DISPLACEMENT control
						sp[motor] <= wrist_joint_angle_control_setpoint[1];
					end
				end
			end			
			if(delay_counter>0) begin
				delay_counter <= delay_counter-1;
			end else begin
				if(spi_done && motor>=(NUMBER_OF_MOTORS-1)) begin
					motor <= 0;
					delay_counter <= CLOCK_SPEED_HZ/update_frequency;
					actual_update_frequency <= CLOCK_SPEED_HZ/counter;
					counter <= 0;
					start_spi_transmission <= 1; 
					// apply elbow joint control setpoints
					if(motor==elbow_agonist && elbow_joint_control) begin
						control_mode[motor] <= 2; // overwrite DISPLACEMENT control
						sp[motor] <= elbow_joint_angle_control_setpoint[0];
					end
					if(motor==elbow_antagonist && elbow_joint_control) begin
						control_mode[motor] <= 2; // overwrite DISPLACEMENT control
						sp[motor] <= elbow_joint_angle_control_setpoint[1];
					end
					// apply wrist joint control setpoints
					if(motor==wrist_agonist && wrist_joint_control) begin
						control_mode[motor] <= 2; // overwrite DISPLACEMENT control
						sp[motor] <= wrist_joint_angle_control_setpoint[0];
					end
					if(motor==wrist_antagonist && wrist_joint_control) begin
						control_mode[motor] <= 2; // overwrite DISPLACEMENT control
						sp[motor] <= wrist_joint_angle_control_setpoint[1];
					end
				end
			end
		end else begin
			// update as fast as possible
			if(spi_done_prev==0 && spi_done) begin
				start_spi_transmission <= 1;
				if(motor<NUMBER_OF_MOTORS-1) begin
					motor <= motor + 1;
				end else begin
					motor <= 0;
					actual_update_frequency <= CLOCK_SPEED_HZ/counter;
					counter <= 0;
				end
				// apply elbow joint control setpoints
				if(motor==elbow_agonist && elbow_joint_control) begin
					control_mode[motor] <= 2; // overwrite DISPLACEMENT control
					sp[motor] <= elbow_joint_angle_control_setpoint[0];
				end
				if(motor==elbow_antagonist && elbow_joint_control) begin
					control_mode[motor] <= 2; // overwrite DISPLACEMENT control
					sp[motor] <= elbow_joint_angle_control_setpoint[1];
				end
				// apply wrist joint control setpoints
				if(motor==wrist_agonist && wrist_joint_control) begin
					control_mode[motor] <= 2; // overwrite DISPLACEMENT control
					sp[motor] <= wrist_joint_angle_control_setpoint[0];
				end
				if(motor==wrist_antagonist && wrist_joint_control) begin
					control_mode[motor] <= 2; // overwrite DISPLACEMENT control
					sp[motor] <= wrist_joint_angle_control_setpoint[1];
				end
			end
		end
	
		// if we are writing via avalon bus and waitrequest is deasserted, write the respective register
		if(write && ~waitrequest) begin
			if((address>>8)<=8'h31 && address[7:0]<NUMBER_OF_MOTORS) begin
				case(address>>8)
					8'h00: Kp[address[7:0]][15:0] <= writedata[15:0];
					8'h01: Ki[address[7:0]][15:0] <= writedata[15:0];
					8'h02: Kd[address[7:0]][15:0] <= writedata[15:0];
					8'h03: sp[address[7:0]][31:0] <= writedata[31:0];
					8'h04: forwardGain[address[7:0]][15:0] <= writedata[15:0];
					8'h05: outputPosMax[address[7:0]][15:0] <= writedata[15:0];
					8'h06: outputNegMax[address[7:0]][15:0] <= writedata[15:0];
					8'h07: IntegralPosMax[address[7:0]][15:0] <= writedata[15:0];
					8'h08: IntegralNegMax[address[7:0]][15:0] <= writedata[15:0];
					8'h09: deadBand[address[7:0]][15:0] <= writedata[15:0];
					8'h0A: control_mode[address[7:0]][1:0] <= writedata[1:0];
					8'h0B: reset_myo_control <= (writedata!=0);
					8'h0C: spi_activated <= (writedata!=0);
					8'h0D: reset_controller[address[7:0]] <= (writedata!=0);
					8'h0E: update_frequency <= writedata;
					8'h0F: gpio_enable <= (writedata!=0);
					8'h10: myo_brick <= writedata;
					8'h11: myo_brick_device_id[address[7:0]][6:0] <= writedata[6:0];
					8'h12: myo_brick_gear_box_ratio[address[7:0]][31:0] <= writedata[31:0];
					8'h13: myo_brick_encoder_multiplier[address[7:0]][31:0] <= writedata[31:0];
					8'h14: outputDivider[address[7:0]][31:0] <= writedata[31:0];
					8'h15: elbow_joint_control <= (writedata[31:0]>0);
					8'h16: elbow_joint_angle_device_id[6:0] <= writedata[31:0];
					8'h17: elbow_agonist[31:0] <= writedata[31:0];
					8'h18: elbow_antagonist[31:0] <= writedata[31:0];
					8'h19: elbow_Kp_joint_angle[31:0] <= writedata[31:0];
					8'h1A: elbow_Kd_joint_angle[31:0] <= writedata[31:0];
					8'h1B: elbow_joint_angle_offset <= writedata[31:0];
					8'h1C: elbow_joint_pretension <= writedata[31:0];
					8'h1D: elbow_joint_deadband <= writedata[31:0];
					8'h1E: elbow_joint_angle_setpoint[31:0] <= writedata[31:0];
					8'h1F: hand_control <= (writedata[31:0]>0);
					8'h20: arm_board_device_id[address[7:0]] <= writedata[6:0];
					8'h21: motor0[address[7:0]] <= writedata[7:0];
					8'h22: motor1[address[7:0]] <= writedata[7:0];
					8'h23: motor2[address[7:0]] <= writedata[7:0];
					8'h24: motor3[address[7:0]] <= writedata[7:0];
					8'h25: motor4[address[7:0]] <= writedata[7:0];
					8'h26: elbow_smooth_distance <= writedata[31:0];
					8'h27: wrist_joint_control <= (writedata[31:0]>0);
					8'h28: wrist_joint_angle_device_id[6:0] <= writedata[31:0];
					8'h29: wrist_agonist[31:0] <= writedata[31:0];
					8'h2A: wrist_antagonist[31:0] <= writedata[31:0];
					8'h2B: wrist_Kp_joint_angle[31:0] <= writedata[31:0];
					8'h2C: wrist_Kd_joint_angle[31:0] <= writedata[31:0];
					8'h2D: wrist_joint_angle_offset <= writedata[31:0];
					8'h2E: wrist_joint_pretension <= writedata[31:0];
					8'h2F: wrist_joint_deadband <= writedata[31:0];
					8'h30: wrist_joint_angle_setpoint[31:0] <= writedata[31:0];
					8'h31: wrist_smooth_distance <= writedata[31:0];
				endcase
			end
		end
		
		if(power_sense_n==0) begin // if power on and delay not reached yet, we count
			if(spi_enable_counter<150000000) begin 
				spi_enable_counter <= spi_enable_counter + 1;
				reset_myo_control <= 1;
			end else begin
				reset_myo_control <= 0;
				spi_activated <= 1;
			end
		end else begin 
			spi_enable_counter <= 0;
			reset_myo_control <= 1;
		end
	end 
end

reg [NUMBER_OF_MOTORS-1:0] myo_brick;
reg [6:0] myo_brick_device_id[NUMBER_OF_MOTORS-1:0];
reg signed [31:0] myo_brick_gear_box_ratio[NUMBER_OF_MOTORS-1:0];
reg signed [31:0] myo_brick_encoder_multiplier[NUMBER_OF_MOTORS-1:0];
reg signed [31:0] motor_spring_angle[NUMBER_OF_MOTORS-1:0];
reg signed [31:0] motor_angle[NUMBER_OF_MOTORS-1:0];
reg signed [31:0] motor_angle_offset[NUMBER_OF_MOTORS-1:0];
reg [31:0] status[NUMBER_OF_MOTORS-1:0];
reg [NUMBER_OF_MOTORS-1:0] myo_brick_ack_error;

generate
	if(ENABLE_MYOBRICK_CONTROL!=0) begin
		reg read_angle;
		wire read_angle_done;
		integer angle_motor_index;
		wire [11:0] angle;
		wire signed [31:0] angle_signed;
		assign angle_signed = angle;
		reg ack_error;

		always @(posedge clock, posedge reset) begin: MYOBRICK_ANGLE_CONTROL_LOGIC
			reg read_angle_done_prev;
			reg [11:0] motor_angle_prev[NUMBER_OF_MOTORS-1:0];
			reg signed [31:0] motor_angle_counter[NUMBER_OF_MOTORS-1:0];
			reg [7:0]i;
			if (reset == 1) begin
				angle_motor_index <= 0;
				read_angle_done_prev <= 0;
				for(i=0; i<NUMBER_OF_MOTORS; i = i+1) begin : reset_angle_counter
					motor_angle_counter[i] <= 0;
				end
			end else begin
				read_angle_done_prev <= read_angle_done;
				read_angle <= 0;
				if(myo_brick[angle_motor_index]==1 && read_angle_done==1) begin
					myo_brick_ack_error[angle_motor_index] <= ack_error;
					read_angle <= 1;
				end
				if((read_angle_done_prev==0 && read_angle_done==1) || myo_brick[angle_motor_index]==0) begin
					// the angle sensor has no internal rotation counter, therefore we gotta count over-/underflow on ower own
					if(power_sense_n) begin // if power sense is off (high), reset the overflow counters
						motor_angle_counter[angle_motor_index] <= 0;
						motor_angle_offset[angle_motor_index] <= angle_signed;
					end else begin
						if(motor_angle_prev[angle_motor_index]>3500 && angle < 500) begin
							motor_angle_counter[angle_motor_index] <= motor_angle_counter[angle_motor_index] + 1;
						end
						if(motor_angle_prev[angle_motor_index]<500 && angle > 3500) begin
							motor_angle_counter[angle_motor_index] <= motor_angle_counter[angle_motor_index] - 1;
						end
					end
					if(ack_error==0) begin // only use valid sensor values
						// motor_angle_offset is set to the angle after power on of the motor boards
						motor_angle[angle_motor_index] <= (angle_signed - motor_angle_offset[angle_motor_index] + motor_angle_counter[angle_motor_index]*4096); 
						// division by gearbox ration gives encoder ticks, angle sensor divided by 4 gives the same range
						motor_spring_angle[angle_motor_index] <= (positions[angle_motor_index]/myo_brick_gear_box_ratio[angle_motor_index])*myo_brick_encoder_multiplier[angle_motor_index] 
																				- ((angle_signed - motor_angle_offset[angle_motor_index] + motor_angle_counter[angle_motor_index]*4096)/4);
						motor_angle_prev[angle_motor_index] <= angle;
					end
					if(angle_motor_index<NUMBER_OF_MOTORS-1) begin
						angle_motor_index <= angle_motor_index + 1;
					end else begin
						angle_motor_index <= 0;
					end
				end
			end 
		end
		
		A1335Control a1335(
			.clock(clock),
			.reset(reset),
			.read_angle(read_angle),
			.read_status(),
			.sda(myobrick_sda),
			.scl(myobrick_scl),
		//	.LED(LED[2:0]),
			.device_id(myo_brick_device_id[angle_motor_index]),
			.done(read_angle_done),
			.angle(angle),
			.status(status[angle_motor_index]),
			.ack_error(ack_error)
		);
	
	end else begin
		assign myobrick_scl = 1'bz;
		assign myobrick_sda = 1'bz;
	end

endgenerate 

wire signed [31:0] joint_angle_signed;

reg elbow_joint_control;
reg signed [31:0] elbow_Kp_joint_angle;
reg signed [31:0] elbow_Kd_joint_angle;
reg [31:0] elbow_agonist;
reg [31:0] elbow_antagonist;
reg signed [31:0] elbow_joint_angle_offset;
reg signed [31:0] elbow_joint_angle_setpoint;
reg signed [31:0] elbow_joint_angle_control_setpoint[1:0];
reg [6:0] elbow_joint_angle_device_id;
reg elbow_joint_angle_ack_error;
reg signed [31:0] elbow_joint_pretension;
reg signed [31:0] elbow_joint_deadband;
reg signed [31:0] elbow_joint_control_result;
reg signed [31:0] elbow_joint_angle_curr;
reg signed [31:0] elbow_joint_angle_prev;
reg signed [31:0] elbow_joint_angle_error;
reg signed [31:0] elbow_joint_angle_error_prev;
reg signed [31:0] elbow_smooth_distance;

reg wrist_joint_control;
reg signed [31:0] wrist_Kp_joint_angle;
reg signed [31:0] wrist_Kd_joint_angle;
reg [31:0] wrist_agonist;
reg [31:0] wrist_antagonist;
reg signed [31:0] wrist_joint_angle_offset;
reg signed [31:0] wrist_joint_angle_setpoint;
reg signed [31:0] wrist_joint_angle_control_setpoint[1:0];
reg [6:0] wrist_joint_angle_device_id;
reg wrist_joint_angle_ack_error;
reg signed [31:0] wrist_joint_pretension;
reg signed [31:0] wrist_joint_deadband;
reg signed [31:0] wrist_joint_control_result;
reg signed [31:0] wrist_joint_angle_curr;
reg signed [31:0] wrist_joint_angle_prev;
reg signed [31:0] wrist_joint_angle_error;
reg signed [31:0] wrist_joint_angle_error_prev;
reg signed [31:0] wrist_smooth_distance;

reg hand_control;
reg arm_board_ack_error;
reg [6:0] arm_board_device_id[3:0];
wire [87:0] arm_board_commandFrame[3:0];
reg [7:0] motor0[3:0];
reg [7:0] motor1[3:0];
reg [7:0] motor2[3:0];
reg [7:0] motor3[3:0];
reg [7:0] motor4[3:0];

genvar k;
generate
	if(ENABLE_ARM_CONTROL!=0) begin
		for(k=0; k<4; k = k+1) begin : assign_control_frames
			assign arm_board_commandFrame[k][7:0] = motor0[k];
			assign arm_board_commandFrame[k][15:8] = motor1[k];
			assign arm_board_commandFrame[k][23:16] = motor2[k];
			assign arm_board_commandFrame[k][31:24] = motor3[k];
			assign arm_board_commandFrame[k][39:32] = motor4[k];
		end
		reg [31:0] number_of_samples;
		reg elbow_read_joint_angle;
		reg wrist_read_joint_angle;
		reg write_hand;
		wire arm_control_done;
		wire [11:0] joint_angle;
		assign joint_angle_signed = joint_angle;
		reg ack_error;
		reg [7:0] arm_control_state;
		parameter IDLE  = 0, READ_ELBOW = 1, READ_WRIST = 2, WRITE_HAND = 3;
		always @(posedge clock, posedge reset) begin: ARM_CONTROL_LOGIC
			reg arm_control_done_prev;
			reg [7:0]i;
			if (reset == 1) begin
				arm_control_done_prev <= 0;
				elbow_joint_angle_error <= 0;
				elbow_joint_angle_prev <= 0;
				write_hand <= 0;
				arm_control_state <= IDLE;
			end else begin
				arm_control_done_prev <= arm_control_done;
				elbow_read_joint_angle <= 0;
				wrist_read_joint_angle <= 0;
				write_hand <= 0;
				case(arm_control_state) 
					IDLE: begin
						if(elbow_joint_control) begin
							arm_control_state <= READ_ELBOW;
							elbow_read_joint_angle <= 1;
						end else if (wrist_joint_control) begin
							arm_control_state <= READ_WRIST;
							wrist_read_joint_angle <= 1;
						end else if(hand_control) begin
							arm_control_state <= WRITE_HAND;
							write_hand <= 1;
						end
					end
					READ_ELBOW: begin
						elbow_joint_angle_ack_error <= ack_error;
						if(arm_control_done_prev==0 && arm_control_done==1) begin
							if(elbow_joint_angle_ack_error==0) begin // only use valid sensor values
								// moving average filter joint angle
								elbow_joint_angle_curr = (9*elbow_joint_angle_prev + 1*(joint_angle_signed + elbow_joint_angle_offset))/10;
								elbow_joint_angle_error = (elbow_joint_angle_setpoint - elbow_joint_angle_curr);
								if((elbow_joint_angle_error>elbow_joint_deadband) || (elbow_joint_angle_error<elbow_joint_deadband)) begin
									elbow_joint_control_result = elbow_Kp_joint_angle * elbow_joint_angle_error + elbow_Kd_joint_angle * (elbow_joint_angle_error - elbow_joint_angle_error_prev);
									if(elbow_joint_control_result<= -1*elbow_smooth_distance) begin 
										elbow_joint_angle_control_setpoint[1] = elbow_joint_pretension - elbow_joint_control_result;
										elbow_joint_angle_control_setpoint[0] = elbow_joint_pretension;
									end else if (elbow_joint_control_result<= elbow_smooth_distance) begin 
										elbow_joint_angle_control_setpoint[1] = elbow_joint_pretension + 
												(elbow_joint_control_result-elbow_smooth_distance)*(elbow_joint_control_result-elbow_smooth_distance)/(4*elbow_smooth_distance);
										elbow_joint_angle_control_setpoint[0] = elbow_joint_pretension + 
												(elbow_joint_control_result+elbow_smooth_distance)*(elbow_joint_control_result+elbow_smooth_distance)/(4*elbow_smooth_distance);
									end else begin
										elbow_joint_angle_control_setpoint[1] = elbow_joint_pretension;
										elbow_joint_angle_control_setpoint[0] = elbow_joint_pretension + elbow_joint_control_result;
									end
								end
								elbow_joint_angle_error_prev = elbow_joint_angle_error;
								elbow_joint_angle_prev = elbow_joint_angle_curr;
							end
							if(wrist_joint_control) begin
								arm_control_state <= READ_WRIST;
								wrist_read_joint_angle <= 1;
							end else if(hand_control) begin
								arm_control_state <= WRITE_HAND;
								write_hand <= 1;
							end else begin 
								arm_control_state <= IDLE;
							end
						end
					end
					READ_WRIST: begin
						wrist_joint_angle_ack_error <= ack_error;
						if(arm_control_done_prev==0 && arm_control_done==1) begin
							if(wrist_joint_angle_ack_error==0) begin // only use valid sensor values
								// moving average filter joint angle
								wrist_joint_angle_curr = (9*wrist_joint_angle_prev + 1*(joint_angle_signed + wrist_joint_angle_offset))/10;
								wrist_joint_angle_error = (wrist_joint_angle_setpoint - wrist_joint_angle_curr);
								if((wrist_joint_angle_error>wrist_joint_deadband) || (wrist_joint_angle_error<wrist_joint_deadband)) begin
									wrist_joint_control_result = wrist_Kp_joint_angle * wrist_joint_angle_error + wrist_Kd_joint_angle * (wrist_joint_angle_error - wrist_joint_angle_error_prev);
									if(wrist_joint_control_result<= -1*wrist_smooth_distance) begin 
										wrist_joint_angle_control_setpoint[1] = wrist_joint_pretension - wrist_joint_control_result;
										wrist_joint_angle_control_setpoint[0] = wrist_joint_pretension;
									end else if (wrist_joint_control_result<= wrist_smooth_distance) begin 
										wrist_joint_angle_control_setpoint[1] = wrist_joint_pretension + 
												(wrist_joint_control_result-wrist_smooth_distance)*(wrist_joint_control_result-wrist_smooth_distance)/(4*wrist_smooth_distance);
										wrist_joint_angle_control_setpoint[0] = wrist_joint_pretension + 
												(wrist_joint_control_result+wrist_smooth_distance)*(wrist_joint_control_result+wrist_smooth_distance)/(4*wrist_smooth_distance);
									end else begin
										wrist_joint_angle_control_setpoint[1] = wrist_joint_pretension;
										wrist_joint_angle_control_setpoint[0] = wrist_joint_pretension + wrist_joint_control_result;
									end
								end
								wrist_joint_angle_error_prev = wrist_joint_angle_error;
								wrist_joint_angle_prev = wrist_joint_angle_curr;
							end
							if(hand_control) begin
								arm_control_state <= WRITE_HAND;
								write_hand <= 1;
							end else begin 
								arm_control_state <= IDLE;
							end
						end
					end
					WRITE_HAND: begin
						arm_board_ack_error <= ack_error;
						if(arm_control_done_prev==0 && arm_control_done==1) begin
							arm_control_state <= IDLE;
						end
					end
					default: arm_control_state <= IDLE;
				endcase
			end 
		end
		
		ArmControl armcontrol(
			.clock(clock),
			.reset(reset),
			.elbow_read_joint_angle(elbow_read_joint_angle),
			.wrist_read_joint_angle(wrist_read_joint_angle),
			.write_hand(write_hand),
			.read_status(),
			.sda(arm_sda),
			.scl(arm_scl),
		//	.LED(LED[2:0]), 
			.elbow_device_id(elbow_joint_angle_device_id),
			.wrist_device_id(wrist_joint_angle_device_id),
			.arm_board_device_id_0(arm_board_device_id[0]),
			.arm_board_device_id_1(arm_board_device_id[1]),
			.arm_board_device_id_2(arm_board_device_id[2]),
			.arm_board_device_id_3(arm_board_device_id[3]),
			.arm_board_commandFrame_0(arm_board_commandFrame[0]),
			.arm_board_commandFrame_1(arm_board_commandFrame[1]),
			.arm_board_commandFrame_2(arm_board_commandFrame[2]),
			.arm_board_commandFrame_3(arm_board_commandFrame[3]),
			.done(arm_control_done),
			.angle(joint_angle),
			.status(),
			.ack_error(ack_error)
		);
	
	end else begin
		assign arm_scl = 1'bz;
		assign arm_sda = 1'bz;
	end

endgenerate 


wire di_req, wr_ack, do_valid, wren, spi_done, ss_n;
wire [0:15] Word;
wire [15:0] data_out;
wire signed [0:15] pwmRef;
wire signed [0:31] position; 
wire signed [0:15] velocity;
wire signed [0:15] current;
wire [0:15] displacement;
wire signed [0:15] sensor1;
wire signed [0:15] sensor2;

// the pwmRef signal is wired to the active motor pid controller output
assign pwmRef = pwmRefs[motor];

// control logic for handling myocontrol frame
SpiControl spi_control(
	.clock(clock),
	.reset(reset_myo_control),
	.di_req(di_req),
	.write_ack(wr_ack),
	.data_read_valid(do_valid),
	.data_read(data_out[15:0]),
	.start(spi_activated && start_spi_transmission),
	.Word(Word[0:15]),
	.wren(wren),
	.spi_done(spi_done),
	.pwmRef(pwmRef),
	.position(position),
	.velocity(velocity),
	.current(current),
	.displacement(displacement),
	.sensor1(sensor1),
	.sensor2(sensor2),
	.ss_n(ss_n)
);

// SPI specs: 2MHz, 16bit MSB, clock phase of 1
spi_master #(16, 1'b0, 1'b1, 2, 5) spi(
	.sclk_i(clock),
	.pclk_i(clock),
	.rst_i(reset_myo_control),
	.spi_miso_i(miso),
	.di_i(Word[0:15]),
	.wren_i(wren),
	.spi_ssel_o(ss_n),
	.spi_sck_o(sck),
	.spi_mosi_o(mosi),
	.di_req_o(di_req),
	.wr_ack_o(wr_ack),
	.do_valid_o(do_valid),
	.do_o(data_out[15:0])
);

// PID controller for NUMBER_OF_MOTORS
genvar j;
generate 
	for(j=0; j<NUMBER_OF_MOTORS; j = j+1) begin : instantiate_pid_controllers
	  PIDController pid_controller(
			.clock(clock),
			.reset(reset_myo_control||reset_controller[j]),
			.Kp(Kp[j]),
			.Kd(Kd[j]),
			.Ki(Ki[j]),
			.sp(sp[j]),
			.forwardGain(forwardGain[j]),
			.outputPosMax(outputPosMax[j]),
			.outputNegMax(outputNegMax[j]),
			.IntegralNegMax(IntegralNegMax[j]),
			.IntegralPosMax(IntegralPosMax[j]),
			.deadBand(deadBand[j]),
			.control_mode(control_mode[j]), // position velocity displacement
			.position(positions[j]),
			.velocity(velocitys[j]),
			.displacement(displacements[j]),
			.outputDivider(outputDivider[j]),
			.update_controller(pid_update==j && update_controller),
			.pwmRef(pwmRefs[j])
		);
		assign ss_n_o[j] = (motor==j?ss_n:1);
	end
endgenerate 


endmodule

