module ball (
	input 			clk,
	input [11:0] 	hcount,  // VGA horizontal counter
	input [10:0] 	vcount,  // VGA vertical counter
	output 			drawBall,
	output [2:0] 	red,
	output [2:0] 	green,
	output [1:0] 	blue
);

	// drawBall;
	assign red = 3'b101;
	assign green = 3'b011;
	assign blue = 2'b01;

	assign drawBall = ((hcount >= 12'd300) && (hcount <= 12'd320) &&
                      (vcount >= 11'd220) && (vcount <= 11'd240));


endmodule