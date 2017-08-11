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

	wire hcount_ov, vcount_ov, video_active, clk;

	// VGA mode parameters
	parameter
	hsync_end   = 12'd96,
	hdat_begin  = 12'd144,
	hdat_end    = 12'd784,
	hpixel_end  = 12'd800,
	vsync_end   = 11'd2,
	vdat_begin  = 11'd35,
	vdat_end    = 11'd513,
	vline_end   = 11'd525;

	/* assign */
	assign LEDG[0] = ~counter[26];
	assign LEDG[1] = ~counter[27];
	assign LEDG[2] = ~counter[28];
	assign LEDG[3] = ~counter[29];

	/* always */
	always @ (posedge clk) begin
		counter <= counter + 1;
	end

	assign hcount_ov = (hcount == hpixel_end);
	always @(posedge clk) begin
		if (hcount_ov)
			hcount <= 12'd0;
		else
			hcount <= hcount + 12'd1;
	end


	assign vcount_ov = (vcount == vline_end);
	always @(posedge clk) begin
		if (hcount_ov)
		begin
			if (vcount_ov)
				vcount <= 11'd0;
			else
				vcount <= vcount + 11'd1;
		end
	end


	assign video_active = ((hdat_begin <= hcount) && (hcount < hdat_end) &&
                      (vdat_begin <= vcount) && (vcount < vdat_end));

	assign hsync = (hcount > hsync_end);
	assign vsync = (vcount > vsync_end);

	assign red   = video_active ?  data[2:0] : 3'b0;
	assign green = video_active ?  data[5:3] : 3'b0;
	assign blue  = video_active ?  data[7:6] : 2'b0;

	// generate "image"
	always @(posedge clk) begin
		data <= vcount[7:0] ^ hcount[7:0];
	end

	assign clk  = CLK25;

endmodule