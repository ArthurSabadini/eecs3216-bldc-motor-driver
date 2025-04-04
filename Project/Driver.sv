module Driver (
	input wire 	CLOCK_50,
	input wire 	[1:0] KEY,        								// Buttons
	output wire [5:0] ARDUINO_IO, 								// D0 - D5 Arduino pins
	output wire [6:0] HEX5, HEX4, HEX3, HEX2, HEX1, HEX0,	// Seven segment display to display operation mode
	output wire [9:0] LEDR											// Leds to show if system is active or not
);

	localparam FREQ_SAMPLES = 5;
	localparam reg [13:0] FREQ_VALS [0:4] = '{4'd3, 14'd5, 14'd6, 14'd7, 14'd8};
	
	localparam AMP_SAMPLES = 5;
	localparam reg [6:0]  AMP_VALS [0:4]  = '{7'd20, 7'd40, 7'd60, 7'd80, 7'd100};
	
	localparam DEAD_TIME_SAMPLES = 5;
	localparam reg [13:0] DEAD_TIME_VALS [0:4] = '{14'd300, 14'd500, 14'd700, 14'd1000, 14'd3000};
	
	localparam F = 7'h0E; // 000_1110 = 0E
	localparam A = 7'h08; // 000_1000 = 08
	localparam H = 7'h09; // 000_1001 = 09 
	localparam D = 7'h21; // 010_0001 = 21
	
	localparam U = 7'b100_0001; // 100_0001 = 41
	localparam N = 7'b010_1011;
	localparam S = 7'b001_0010;
	localparam OFF = 8'hFF;
	
	typedef enum logic [1:0] {
		FREQ_CONF,
		AMP_CONF,
		DEAD_TIME_CONF
	} config_state;
	
	// Initially not active
	reg KEY0, KEY1, BOTH_KEYS, ACTIVE = 0;
	reg [2:0] FREQ_OFFSET = 0, AMP_OFFSET = 3'd4, DEAD_TIME_OFFSET = 0;
	
	inputDriver buttonsDriver(.clk(CLOCK_50), .KEY(KEY), .key0(KEY0), .key1(KEY1), .both(BOTH_KEYS));
	
	SVPWM sp1(
		.clk(CLOCK_50), .active(ACTIVE), .AMPLITUDE(AMP_VALS[AMP_OFFSET]), 
		.FREQ(FREQ_VALS[FREQ_OFFSET]), .DEAD_TIME_US(DEAD_TIME_VALS[DEAD_TIME_OFFSET]), .S(ARDUINO_IO)
	);
	
	// Parameters for UI
	reg [3:0] freq_digit, freq_ones_digit;
	reg [6:0] freq_digit_hex, freq_ones_digit_hex;
	
	assign freq_digit = FREQ_VALS[FREQ_OFFSET] / 10;
	assign freq_ones_digit = FREQ_VALS[FREQ_OFFSET] % 10;
	
	SevenSegDecoder deco1(.inp(freq_digit), .leds(freq_digit_hex));
	SevenSegDecoder deco2(.inp(freq_ones_digit), .leds(freq_ones_digit_hex));
	
	// Parameters to be displayed
	reg [11:0] amp_digit = 12'h020;
	reg [20:0] amp_digits_hex;
	
	// Parameters to be displayed
	reg [11:0] dead_time_digit = 12'h300;
	reg [20:0] dead_time_digits_hex;
	
	SevenSegDecoder deco3(.inp(amp_digit[3:0]), .leds(amp_digits_hex[6:0]));
	SevenSegDecoder deco4(.inp(amp_digit[7:4]), .leds(amp_digits_hex[13:7]));
	SevenSegDecoder deco5(.inp(amp_digit[11:8]), .leds(amp_digits_hex[20:14]));
	
	SevenSegDecoder deco6(.inp(dead_time_digit[3:0]), .leds(dead_time_digits_hex[6:0]));
	SevenSegDecoder deco7(.inp(dead_time_digit[7:4]), .leds(dead_time_digits_hex[13:7]));
	SevenSegDecoder deco8(.inp(dead_time_digit[11:8]), .leds(dead_time_digits_hex[20:14]));
	
	always_comb begin		
		case(AMP_OFFSET)
			3'd0: 	amp_digit = 12'h020;
			3'd1: 	amp_digit = 12'h040; 
			3'd2: 	amp_digit = 12'h060;
			3'd3: 	amp_digit = 12'h080;
			3'd4: 	amp_digit = 12'h100;
			default: amp_digit = 12'h020;
		endcase
		
		case(DEAD_TIME_OFFSET)
			3'd0: 	dead_time_digit = 12'h300;
			3'd1: 	dead_time_digit = 12'h500; 
			3'd2: 	dead_time_digit = 12'h700;
			3'd3: 	dead_time_digit = 12'h001;
			3'd4: 	dead_time_digit = 12'h003;
			default: dead_time_digit = 12'h300;
		endcase
	end
	
	// Button KEY1 is used as an emergency stop. When pressed the gate voltages of MOSFETs is set to 0V	
	always_ff @(posedge KEY1) begin
		ACTIVE <= ~ACTIVE;
		LEDR <= ACTIVE? 10'h000: 10'hFFF;
	end
	
	// Button KEY0 is used to change the current parameter configuration.
	// If current configuration is in the frequency mode, this button modifies the frequency
	config_state CURR_CONFIG = FREQ_CONF, NEXT_CONFIG = FREQ_CONF;
	always_ff @(posedge KEY0) begin
		case(CURR_CONFIG)
			FREQ_CONF: FREQ_OFFSET <= (FREQ_OFFSET + 1) % FREQ_SAMPLES;
			AMP_CONF:  AMP_OFFSET <= (AMP_OFFSET + 1) % AMP_SAMPLES;
			DEAD_TIME_CONF:	DEAD_TIME_OFFSET <= (DEAD_TIME_OFFSET + 1) % DEAD_TIME_SAMPLES;
			default:   FREQ_OFFSET <= (FREQ_OFFSET + 1) % FREQ_SAMPLES;
		endcase
	end
	
	// This block outputs the current configuration in the seven segment displays
	always_comb begin
		case(CURR_CONFIG)
			FREQ_CONF: begin 							
				// Write current freq to HEX
				HEX5 = F;
				HEX4 = OFF;
				HEX3 = OFF;
				HEX2 = freq_digit_hex;
				HEX1 = freq_ones_digit_hex;
				HEX0 = H;
			end
			AMP_CONF: begin			
				// Write current amplitude to HEX
				HEX5 = A;
				HEX4 = OFF;
				{HEX3, HEX2, HEX1} = amp_digits_hex;
				HEX0 = A;
			end
			DEAD_TIME_CONF: begin
				// Write current amplitude to HEX
				HEX5 = D;
				{HEX4, HEX3, HEX2} = dead_time_digits_hex;
				HEX1 = (DEAD_TIME_OFFSET <= 3'd2)? N: U;
				HEX0 = S;
			end
			default: begin
				// Write current freqto HEX
				HEX5 = F;
				HEX4 = OFF;
				HEX3 = OFF;
				HEX2 = freq_digit_hex;
				HEX1 = freq_ones_digit_hex;
				HEX0 = H;
			end
		endcase	
	end
	
	// When both buttons (KEY0 and KEY1) are pressed we change the current configuration mode
	always_ff @(posedge BOTH_KEYS) begin
		case(CURR_CONFIG)
			FREQ_CONF: NEXT_CONFIG <= AMP_CONF;
			AMP_CONF: NEXT_CONFIG <= DEAD_TIME_CONF;
			DEAD_TIME_CONF: NEXT_CONFIG <= FREQ_CONF; 
			default: NEXT_CONFIG <= FREQ_CONF;
		endcase
	end
	
	always_ff @(posedge CLOCK_50) begin
		CURR_CONFIG <= NEXT_CONFIG;
	end

endmodule 
