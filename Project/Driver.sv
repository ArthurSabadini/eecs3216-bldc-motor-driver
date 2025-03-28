module Driver (
	input wire CLOCK_50,
	input wire [1:0] KEY,        // Buttons
	output wire [5:0] ARDUINO_IO, // D0 and D1 Arduino pins
	output wire [6:0] HEX5, HEX4, HEX3, HEX2, HEX1, HEX0	    // Seven segment display to display operation mode
);

	localparam FREQ_SAMPLES = 5;
	localparam reg [13:0] FREQ_VALS [0:4] = '{4'd3, 14'd5, 14'd10, 14'd15, 14'd20};//'{14'd1, 14'd2, 14'd3, 14'd4, 14'd5};
	localparam reg [6:0]  AMP_VALS [0:4]  = '{7'd20, 7'd40, 7'd60, 7'd80, 7'd100};
	
	localparam F = 7'h0E; // 000_1110 = 0E
	localparam A = 7'h08; // 000_1000 = 08
	localparam H = 7'h09; // 000_1001 = 09 
	
	reg KEY0, KEY1, BOTH_KEYS, ACTIVE = 1;
	reg [2:0] FREQ_OFFSET = 0, AMP_OFFSET = 3'd4;
	
	inputDriver buttonsDriver(.clk(CLOCK_50), .KEY(KEY), .key0(KEY0), .key1(KEY1), .both(BOTH_KEYS));
	
	SVPWM sp1(.clk(CLOCK_50), .active(ACTIVE), .AMPLITUDE(AMP_VALS[AMP_OFFSET]), .FREQ(FREQ_VALS[FREQ_OFFSET]), .DEAD_TIME_US(14'd1), .S(ARDUINO_IO));
	
	// Parameters for UI
	reg [3:0] freq_digit, freq_ones_digit;
	reg [6:0] freq_digit_hex, freq_ones_digit_hex;
	
	assign freq_digit = FREQ_VALS[FREQ_OFFSET] / 10; // 1000
	assign freq_ones_digit = FREQ_VALS[FREQ_OFFSET] % 10; // 1000
	
	SevenSegDecoder deco1(.inp(freq_digit), .leds(freq_digit_hex));
	SevenSegDecoder deco2(.inp(freq_ones_digit), .leds(freq_ones_digit_hex));
	
	// Parameters to be displayed
	reg [11:0] amp_digit = 12'h020;
	reg [20:0] amp_digits_hex;
	
	SevenSegDecoder deco3(.inp(amp_digit[3:0]), .leds(amp_digits_hex[6:0]));
	SevenSegDecoder deco4(.inp(amp_digit[7:4]), .leds(amp_digits_hex[13:7]));
	SevenSegDecoder deco5(.inp(amp_digit[11:8]), .leds(amp_digits_hex[20:14]));
	
	always_comb begin		
		case(AMP_OFFSET)
			3'd0: amp_digit = 12'h020;
			3'd1: amp_digit = 12'h040; 
			3'd2: amp_digit = 12'h060;
			3'd3: amp_digit = 12'h080;
			3'd4: amp_digit = 12'h100;
			default: amp_digit = 12'h020;
		endcase
		
		// Write current freq/amp to HEX
		HEX5 = freq_digit_hex;
		HEX4 = freq_ones_digit_hex;
		HEX3 = H;
		{HEX2, HEX1, HEX0} = amp_digits_hex;
	end
	
	// Input Updates
	always_ff @(posedge BOTH_KEYS) ACTIVE <= ~ACTIVE;
	always_ff @(posedge KEY0) FREQ_OFFSET <= (FREQ_OFFSET + 1) % FREQ_SAMPLES;
	always_ff @(posedge KEY1) AMP_OFFSET <= (AMP_OFFSET + 1) % FREQ_SAMPLES;

endmodule 