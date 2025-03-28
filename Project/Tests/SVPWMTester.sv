`timescale 1ns/1ps

module SVPWMTester();

	reg clk = 0;
	reg [5:0] LEGS1, LEGS2;
	
	SVPWM svpwm1(.clk(clk), .active(1'd1), .AMPLITUDE(7'd100), .FREQ(14'd2), .DEAD_TIME_US(14'd1), .S(LEGS1));
	SVPWM svpwm2(.clk(clk), .active(1'd1), .AMPLITUDE(7'd100), .FREQ(14'd60), .DEAD_TIME_US(14'd1), .S(LEGS2));
	
	always #10 clk <= ~clk;

endmodule 