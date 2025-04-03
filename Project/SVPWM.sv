module SVPWM (
	input wire clk,
	input wire active,
	input wire [6:0] AMPLITUDE,
	input wire [13:0] FREQ,
	input wire [13:0] DEAD_TIME_US,
	output reg [5:0] S
);

	localparam SAMPLES = 102;
	localparam NUMBER_STATES = 6;
	localparam NUMBER_VECTORS = 7;
	localparam CLOCK_PERIOD = 50000000;
	
	// Samples at 1 kHz. Normalized in units of clock cycle at 50MHz
	localparam reg [15:0] SIN_LUT [0:SAMPLES-1] = '{
		16'd24999, 16'd26538, 16'd28071, 16'd29593, 16'd31097, 16'd32578, 16'd34030, 16'd35448, 16'd36826, 16'd38160, 16'd39443, 16'd40672, 
		16'd41841, 16'd42946, 16'd43984, 16'd44949, 16'd45839, 16'd46649, 16'd47378, 16'd48021, 16'd48577, 16'd49044, 16'd49420, 16'd49703, 
		16'd49892, 16'd49987, 16'd49987, 16'd49892, 16'd49703, 16'd49420, 16'd49044, 16'd48577, 16'd48021, 16'd47378, 16'd46649, 16'd45839, 
		16'd44949, 16'd43984, 16'd42946, 16'd41841, 16'd40672, 16'd39443, 16'd38160, 16'd36826, 16'd35448, 16'd34030, 16'd32578, 16'd31097, 
		16'd29593, 16'd28071, 16'd26538, 16'd24999, 16'd23460, 16'd21927, 16'd20405, 16'd18901, 16'd17420, 16'd15968, 16'd14550, 16'd13172, 
		16'd11838, 16'd10555, 16'd9326 , 16'd8157 , 16'd7052 , 16'd6014 , 16'd5049 , 16'd4159 , 16'd3349 , 16'd2620 , 16'd1977 , 16'd1421 , 
		16'd954  , 16'd578  , 16'd295  , 16'd106  , 16'd11   , 16'd11   , 16'd106  , 16'd295  , 16'd578  , 16'd954  , 16'd1421 , 16'd1977 , 
		16'd2620 , 16'd3349 , 16'd4159 , 16'd5049 , 16'd6014 , 16'd7052 , 16'd8157 , 16'd9326 , 16'd10555, 16'd11838, 16'd13172, 16'd14550, 
		16'd15968, 16'd17420, 16'd18901, 16'd20405, 16'd21927, 16'd23460
	};
	
	typedef enum logic [2:0] { S1, S2, S3, S4, S5, S6 } state_sector;
	
	typedef enum logic [2:0] {
		V0 = 3'b000, V1 = 3'b100, V2 = 3'b110, V3 = 3'b010,
		V4 = 3'b011, V5 = 3'b001, V6 = 3'b101, V7 = 3'b111
	} state_vector;
	
	localparam state_vector SECTOR_VECTORS_LUT [0:NUMBER_STATES-1][0:NUMBER_VECTORS-1] = '{
		'{V0, V1, V2, V7, V2, V1, V0}, '{V0, V3, V2, V7, V2, V3, V0}, 
		'{V0, V3, V4, V7, V4, V3, V0}, '{V0, V5, V4, V7, V4, V5, V0}, 
		'{V0, V5, V6, V7, V6, V5, V0}, '{V0, V1, V6, V7, V6, V1, V0}
	};
	
	reg [2:0] vector_index = 0;
	reg [24:0] sector_counter = 0, vector_counter = 0, sample_counter = 0;
	reg [24:0] SECTOR_PERIOD, VECTOR_PERIOD = 17'd0;
	reg [24:0] SAMPLE_PERIOD, DEAD_TIME_PERIOD;
	
	// Period spent in each sector, we must cover all sectors within the input period time.
	assign SECTOR_PERIOD = (CLOCK_PERIOD / (NUMBER_STATES * FREQ)) - 1;
	
	// Fix Dead Time Period. 1us at 50MHz = 50 cycles
	assign DEAD_TIME_PERIOD = 50 * DEAD_TIME_US;
	
	// Update TIME for SAMPLES/NUMBER_STATES = 17 samples per sector.
	assign SAMPLE_PERIOD = NUMBER_STATES * (SECTOR_PERIOD+1) / SAMPLES - 1;
	
	// SVPWM parameters calculations
	reg [24:0] AMP, TIME = 0;
	reg [24:0] T0, T1, T2;
	
	// Normalizing by 100 and Dividing by sqrt{3}	
	// Note 2^19 *100/sqrt{3} = 0xBD2
	assign AMP = (AMPLITUDE * SAMPLE_PERIOD * 40'hBD2) >> 19;
	
	// Normalizing by max SIN_LUT value = 49999
	assign T1 = AMP * SIN_LUT[TIME % SAMPLES] / 49999;
	assign T2 = AMP * SIN_LUT[(TIME + (SAMPLES * 120 / 360)) % SAMPLES] / 49999;
	assign T0 = SAMPLE_PERIOD - (T1 + T2);
	
	// Sector and Vector Transition
	state_sector CURR_SEC = S1, NEXT_SEC = S1;
	state_vector CURR_VEC = V0, NEXT_VEC = V0, NEXT_PREDICT_VEC = V0;
	always_comb begin
		case(CURR_SEC)
			S1: begin 
				NEXT_SEC = (sector_counter < SECTOR_PERIOD)? S1: S2; 
				NEXT_VEC = SECTOR_VECTORS_LUT[0][vector_index]; 
			end
			S2: begin 
				NEXT_SEC = (sector_counter < SECTOR_PERIOD)? S2: S3; 
				NEXT_VEC = SECTOR_VECTORS_LUT[1][vector_index]; 
			end
			S3: begin 
				NEXT_SEC = (sector_counter < SECTOR_PERIOD)? S3: S4; 
				NEXT_VEC = SECTOR_VECTORS_LUT[2][vector_index]; 
			end
			S4: begin 
				NEXT_SEC = (sector_counter < SECTOR_PERIOD)? S4: S5; 
				NEXT_VEC = SECTOR_VECTORS_LUT[3][vector_index]; 
			end
			S5: begin 
				NEXT_SEC = (sector_counter < SECTOR_PERIOD)? S5: S6; 
				NEXT_VEC = SECTOR_VECTORS_LUT[4][vector_index]; 
			end
			S6: begin 
				NEXT_SEC = (sector_counter < SECTOR_PERIOD)? S6: S1; 
				NEXT_VEC = SECTOR_VECTORS_LUT[5][vector_index]; 
			end
		endcase
		
		case(CURR_SEC)
			S1: NEXT_PREDICT_VEC = SECTOR_VECTORS_LUT[0][(vector_index == 6)? 0 : vector_index+1];
			S2: NEXT_PREDICT_VEC = SECTOR_VECTORS_LUT[1][(vector_index == 6)? 0 : vector_index+1];
			S3: NEXT_PREDICT_VEC = SECTOR_VECTORS_LUT[2][(vector_index == 6)? 0 : vector_index+1];
			S4: NEXT_PREDICT_VEC = SECTOR_VECTORS_LUT[3][(vector_index == 6)? 0 : vector_index+1];
			S5: NEXT_PREDICT_VEC = SECTOR_VECTORS_LUT[4][(vector_index == 6)? 0 : vector_index+1];
			S6: NEXT_PREDICT_VEC = SECTOR_VECTORS_LUT[5][(vector_index == 6)? 0 : vector_index+1];
		endcase
		
		// Inverting (top) Output
		// If not active (on an emergency stop for example) hard set top values to 0
		
		// CHANGE THIS TO 1 WHEN IMPLEMENTING NOT GATES!
		S[2:0] = active? ~CURR_VEC : 0;
	end
	
	// Period Update
	always_comb begin		
		case(vector_index)
			0: VECTOR_PERIOD = T0 / 4;
			1: VECTOR_PERIOD = T1 / 2;
			2: VECTOR_PERIOD = T2 / 2;
			3: VECTOR_PERIOD = T0 / 2;
			4: VECTOR_PERIOD = T2 / 2;
			5: VECTOR_PERIOD = T1 / 2;
			6: VECTOR_PERIOD = T0 / 4;
			default: VECTOR_PERIOD = T0 / 4;
		endcase
	end
	
	// States Transitions
	always_ff @(posedge clk or negedge active) begin
		if(~active) begin
			// If not active (on an emergency stop for example) hard set bottom values to 0
			
			// CHANGE THIS TO 1 WHEN IMPLEMENTING NOT GATES!
			S[5:3] <= 0;
		end else begin
			sector_counter <= (sector_counter < SECTOR_PERIOD)? sector_counter + 1: 0;
			
			// Forcefully reset parameters
			// Output may be out of sync if frequency is not a divisor of system clock (50MHz)
			if((sample_counter >= SAMPLE_PERIOD) | (sector_counter >= SECTOR_PERIOD)) begin
				vector_counter <= 0;
				vector_index <= 0;
				sample_counter <= 0;
				TIME <= (TIME + 1) % SAMPLES;
				
			// Incrementing parameters
			end else begin
				vector_counter <= (vector_counter < VECTOR_PERIOD)? vector_counter + 1: 0;
				sample_counter <= sample_counter + 1;
				
				// Only increment vector_index at the end of the vector period
				if(vector_counter >= VECTOR_PERIOD) vector_index <= (vector_index + 1) % (NUMBER_VECTORS);
			end
			
			// Dead Time Implementation for Non-Inverting (bottom) Output
			// Fist output is undefined, implement a pull down resistor.
			if(vector_counter >= (VECTOR_PERIOD - (DEAD_TIME_PERIOD / 2))) begin
				// Initially both signals (top and bottom) are 0, and suppose the top output
				// goes to 1 at the beggining of a vector transition. The bottom signal waits for
				// DEAT_TIME_PERIOD / 2 at the end of the cycle and makes a prediction of what the next vector will be
				// (really we know what it is since the vector sequence is fixed).
				// If the prediction is correct we assign the vector value to the bottom output
				// (since the top output is inverted) else we set it to 0 for safety.
			
				S[3] <= (NEXT_PREDICT_VEC[0] == CURR_VEC[0])? NEXT_PREDICT_VEC[0]: 0;
				S[4] <= (NEXT_PREDICT_VEC[1] == CURR_VEC[1])? NEXT_PREDICT_VEC[1]: 0;	
				S[5] <= (NEXT_PREDICT_VEC[2] == CURR_VEC[2])? NEXT_PREDICT_VEC[2]: 0;	
			end else if(vector_counter >= DEAD_TIME_PERIOD / 2) begin
				// After the initial DEAD_TIME_PERIOD we set the bottom output to the current vector value 
				// (since top output is inverted).
				S[5:3] <= CURR_VEC;
			end
			
			CURR_SEC <= NEXT_SEC;
			CURR_VEC <= NEXT_VEC;
		end
 	end

endmodule 
