module vgapong (
	input 			CLK25,
	output [3:0] 	LEDG,
	output [2:0] 	red,
	output [2:0] 	green,
	output [1:0] 	blue,
	output 			hsync, vsync
);
	/* reg */
	reg [32:0] counter;

	reg [11:0] hcount;  // VGA horizontal counter
	reg [10:0] vcount;  // VGA vertical counter
	reg [7:0] data;     // RGB data
	reg hsync_reg;
	reg vsync_reg;

	wire hcount_ov, vcount_ov, video_active, clk;

	// VGA mode parameters
	parameter
	HDISP = 12'd640,
	RIGHTBORDER = 12'd16,
	HFLYBACK = 12'd96,
	LEFTBORDER = 12'd48,
	VDISP = 11'd480,
	BOTTOMBORDER = 11'd10,
	VFLYBACK = 11'd2,
	TOPBORDER = 11'd33;

	/* assign */
	assign LEDG[0] = ~counter[26];
	assign LEDG[1] = ~counter[27];
	assign LEDG[2] = ~counter[28];
	assign LEDG[3] = ~counter[29];

	/* always */
	always @ (posedge clk) begin
		counter <= counter + 1;
	end

	assign hcount_ov = (hcount == (HDISP + RIGHTBORDER + HFLYBACK + LEFTBORDER));
	always @(posedge clk) begin
		if (hcount_ov)
			hcount <= 12'd0;
		else
			hcount <= hcount + 12'd1;
	end


	assign vcount_ov = (vcount == (VDISP + BOTTOMBORDER + VFLYBACK + TOPBORDER));
	always @(posedge clk) begin
		if (hcount_ov)
		begin
			if (vcount_ov)
				vcount <= 11'd0;
			else
				vcount <= vcount + 11'd1;
		end
	end


	assign video_active = ((hcount < HDISP) && (vcount < VDISP));

	//assign hsync = ((hcount < (HDISP + RIGHTBORDER)) || (hcount > (HDISP + RIGHTBORDER + HFLYBACK)));
	//assign vsync = ((vcount < (VDISP + BOTTOMBORDER)) || (vcount > (VDISP + BOTTOMBORDER + VFLYBACK)));
	assign hsync = hsync_reg;
	assign vsync = vsync_reg;
	always @(*) begin
		if ((hcount > (HDISP + RIGHTBORDER)) && (hcount < (HDISP + RIGHTBORDER + HFLYBACK)))
			hsync_reg = 1'b0;	
		else
			hsync_reg = 1'b1;
		if ((vcount > (VDISP + BOTTOMBORDER)) && (vcount < (VDISP + BOTTOMBORDER + VFLYBACK)))
			vsync_reg = 1'b0;
		else
			vsync_reg = 1'b1;
	end
	
	
	assign red   = video_active ?  ( drawBall ? redBall[2:0] : data[2:0]) : 3'b0;
	assign green = video_active ?  ( drawBall ? greenBall[2:0] : data[5:3]) : 3'b0;
	assign blue  = video_active ?  ( drawBall ? blueBall[1:0] : data[7:6]) : 2'b0;

	// generate "image"
	always @(posedge clk) begin
		data[7:6] = hcount[6] ? 2'b0 : 2'b11; //blue
		data[2:0] = hcount[7] ? 3'b0 : 3'b111; //red
		data[5:3] = hcount[8] ? 3'b0 : 3'b111; //green
	end

	assign clk  = CLK25;

	wire drawBall;
	wire [2:0] redBall;
	wire [2:0] greenBall;
	wire [1:0] blueBall;


	ball  ball_inst(
		.clk(clk),
		.hcount(hcount),  // VGA horizontal counter
		.vcount(vcount),  // VGA vertical counter
		.drawBall(drawBall),
		.red(redBall),
		.green(greenBall),
		.blue(blueBall)
	);


endmodule