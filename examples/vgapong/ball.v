module ball (
	input 			clk,
	input 			vcount_ov,
	input 			hcount_ov,
	input [11:0] 	hcount,  // VGA horizontal counter
	input [10:0] 	vcount,  // VGA vertical counter
	output 			drawBall,
	output [2:0] 	red,
	output [2:0] 	green,
	output [1:0] 	blue
);

	reg [9:0] ballX;
	reg [9:0] ballY;

	reg dX;
	reg dY;

	// drawBall;
	assign red = 3'b101;
	assign green = 3'b011;
	assign blue = 2'b01;
	
	always @ (posedge clk) begin
		if (ballX < 20) 			dX <= 1;
		else if (ballX > 600)	dX <= 0;
		else 							dX <= dX;

		if (ballY < 20)			dY <= 1;
		else if (ballY > 440)	dY <= 0;
		else 							dY <= dY;
	end

	always @ (posedge clk) begin
		if (vcount_ov && hcount_ov) begin

			if (dX)	ballX <= ballX + 11;
			else		ballX <= ballX - 11;

			if (dY)	ballY <= ballY + 11;
			else		ballY <= ballY - 11;
		end
	end
	
	assign drawBall = ((hcount >= ballX) && (hcount <= ballX + 20) &&
                      (vcount >= ballY) && (vcount <= ballY + 20));


endmodule