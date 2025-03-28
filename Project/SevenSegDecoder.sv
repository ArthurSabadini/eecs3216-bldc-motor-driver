module SevenSegDecoder (
    input [3:0] inp,
    output [6:0] leds
);

    /*  For Seven Segment Display on DE10-Lite, 0 is high and 1 is low.
     *
     *      --0--    
     *     |     |
     *     5     1
     *     |     |
     *      --6--
     *     |     |
     *     4     2
     *     |     |
     *      --3--
     * */

    // f_0 = ~a~c(b XOR d) + ad(b XOR c)
    assign leds[0] = (~inp[3] & ~inp[1]) & (inp[2] ^ inp[0]) | (inp[3] & inp[0] & (inp[2] ^ inp[1])); 

    // f_1 = b~d(a + c) + d(ac + ~ab~c)
    assign leds[1] = (inp[2] & ~inp[0]) & (inp[3] | inp[1]) | (inp[0] & (inp[3] & inp[1] | ~inp[3] & inp[2] & ~inp[1]));

    // f_2 = ab(c + ~d) + ~a~bc~d
    assign leds[2] = ((inp[3] & inp[2]) & (inp[1] | ~inp[0])) | (~inp[3] & ~inp[2] & inp[1] & ~inp[0]);

    // f_3 = ~a~b(b XOR d) + bcd + a~bc~d
    assign leds[3] = (~inp[3] & ~inp[1]) & (inp[2] ^ inp[0]) | (inp[2] & inp[1] & inp[0]) | (inp[3] & ~inp[2] & inp[1] & ~inp[0]);

    // f_4 = ~bd~c + ~a(b~c + ~bd + cd)
    assign leds[4] = (~inp[2] & inp[0] & ~inp[1]) | ~inp[3] & ((inp[2] & ~inp[1]) | (~inp[2] & inp[0]) | (inp[1] & inp[0]));

    // f_5 = ab~cd + ~a(~bd + cd + ~bc)
    assign leds[5] = inp[3] & inp[2] & ~inp[1] & inp[0] | ~inp[3] & (~inp[2] & inp[0] | inp[1] & inp[0] | ~inp[2] & inp[1]);

    // f_6 = ~a~b~c + ~abcd + ab~c~d
    assign leds[6] = ~inp[3] & ~inp[2] & ~inp[1] | ~inp[3] & inp[2] & inp[1] & inp[0] | inp[3] & inp[2] & ~inp[1] & ~inp[0];

endmodule
