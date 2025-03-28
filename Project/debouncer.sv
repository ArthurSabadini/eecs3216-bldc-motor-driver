module debouncer (
    input wire clk_in, // 50MHz System Clock
    input wire button, 
    output reg sig
);

    // Choose low delay for debugging.
    parameter DELAY_MS = 100;
    localparam COUNTER_MAX = DELAY_MS * 50000; // For 50MHz -> 50k cycles = 1ms

    typedef enum logic[1:0] {
        IDLE,
        NEG_EDGE,
        POS_EDGE 
    } state_t;
    
    state_t curr_state = IDLE, next_state;
    reg [25:0] counter = 0; // We have to use the maximun amount we can count

    always_comb begin
        case(curr_state)
            IDLE: next_state = button? IDLE: NEG_EDGE;  // Wating for press (negedge)
            NEG_EDGE: begin 
					 // Waiting for button natural state (not pressed)
                if(counter >= COUNTER_MAX - 1'b1) next_state = button? POS_EDGE: NEG_EDGE;
                else next_state = NEG_EDGE;
            end
            POS_EDGE: next_state = (counter < COUNTER_MAX - 1'b1)? POS_EDGE: IDLE;
            default: next_state = IDLE;
        endcase

        // Output
        sig = (curr_state == IDLE)? 1'b0: 1'b1;
    end

    always_ff @(posedge clk_in) begin
        curr_state <= next_state;

        case(curr_state)
            IDLE: counter <= 0;
            NEG_EDGE: begin // Wating for signal to stabilize
                counter <= (counter < COUNTER_MAX - 1'b1)? counter + 1'b1: 1'b0;
            end
            POS_EDGE: if(counter < COUNTER_MAX - 1'b1) counter <= counter + 1'b1;
        endcase
    end 
endmodule
