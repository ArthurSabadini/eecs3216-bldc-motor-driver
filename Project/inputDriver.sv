module inputDriver (
    input wire clk,
    input wire [1:0] KEY,
	 output reg key0, key1, both
);

    parameter SYNC_DELAY_MS = 50;
    localparam COUNTER_MAX = SYNC_DELAY_MS * 50000; // For 50MHz -> 50k cycles = 1ms

    // States of inputDriver FSM
    typedef enum logic[1:0] {
        LISTEN,
        KEY0_PRESS,
        KEY1_PRESS,
        BOTH_PRESS 
    } state_t;

    reg [1:0] buttonPressed;

	// Deboucing input
    debouncer #(.DELAY_MS(100)) deb0(.clk_in(clk), .button(KEY[0]), .sig(buttonPressed[0]));
    debouncer #(.DELAY_MS(100)) deb1(.clk_in(clk), .button(KEY[1]), .sig(buttonPressed[1]));

    state_t curr_state = LISTEN, next_state = LISTEN;
    reg waitInput = 0; 
    reg [25:0] counter = 0;

    always_ff @(posedge clk) begin 
        curr_state <= next_state;
        counter <= waitInput? counter + 1'b1: 1'b0;
		  
		  // Update signals after sync delay
		  if(counter >= COUNTER_MAX - 1) begin
				case(curr_state)
					LISTEN: {key0, key1, both} <= 3'b000;
					KEY0_PRESS: {key0, key1, both} <= 3'b100;
					KEY1_PRESS: {key0, key1, both} <= 3'b010;
					BOTH_PRESS: {key0, key1, both} <= 3'b001;
				endcase
		  end else if (!waitInput) begin
				case(curr_state)
					LISTEN: {key0, key1, both} <= 3'b000;
					BOTH_PRESS: {key0, key1, both} <= 3'b001;
				endcase
		  end
    end
	 
	 // waitInput Logic
	 always_comb begin
			case(curr_state)
				// If KEY[0] xor KEY[1] pressed, then wait for more input
            LISTEN: waitInput = buttonPressed[0] ^ buttonPressed[1];
            KEY0_PRESS: begin
                // Wait for other button to be pressed. If pressed go to
                // BOTH_PRESS. Else perform the action of this button.
                if(counter < COUNTER_MAX - 1) waitInput = buttonPressed[1]? 1'b0: 1'b1;
                else waitInput = 0; 
            end 
            KEY1_PRESS: begin 
                // Same logic as above, but for the other button.
					if(counter < COUNTER_MAX - 1) waitInput = buttonPressed[0]? 1'b0: 1'b1;
					else waitInput = 0; 
				end
            BOTH_PRESS: waitInput = 0;
        endcase
	 end
	 
	 // States Transition Logic
	 always_comb begin
			case(curr_state)
            LISTEN: begin // Listen for presses
                case(buttonPressed) 
                    2'b01: next_state = KEY0_PRESS;
                    2'b10: next_state = KEY1_PRESS;
                    2'b11: next_state = BOTH_PRESS;
						  default: next_state = LISTEN;
                endcase
				end
				KEY0_PRESS: begin
					if(!buttonPressed[0]) next_state = LISTEN;
					else if(counter < COUNTER_MAX - 1) next_state = buttonPressed[1]? BOTH_PRESS: KEY0_PRESS;
					else next_state = LISTEN;
				end
				KEY1_PRESS: begin
					if(!buttonPressed[1]) next_state = LISTEN;
					else if(counter < COUNTER_MAX - 1) next_state = buttonPressed[0]? BOTH_PRESS: KEY1_PRESS;
					else next_state = LISTEN;
				end
				BOTH_PRESS: next_state = (buttonPressed == 2'b00)? LISTEN: BOTH_PRESS;
			endcase
	 end

endmodule
