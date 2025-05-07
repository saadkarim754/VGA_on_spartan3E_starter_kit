`timescale 1ns / 1ps
module top (
    input wire clk,
    input wire [3:0] sw,  // sw0-left, sw1-right, sw2-up, sw3-down
    output wire Hsync,
    output wire Vsync,
    output wire Red,
    output wire Green,
    output wire Blue
);

  // VGA Timing Constants
  localparam H_SYNC_PULSE   = 96;
  localparam H_BACK_PORCH   = 48;
  localparam H_DISPLAY      = 640;
  localparam H_FRONT_PORCH  = 16;
  localparam H_TOTAL        = 800;

  localparam V_SYNC_PULSE   = 2;
  localparam V_BACK_PORCH   = 29;
  localparam V_DISPLAY      = 480;
  localparam V_FRONT_PORCH  = 10;
  localparam V_TOTAL        = 521;

  localparam H_DISPLAY_START = H_SYNC_PULSE + H_BACK_PORCH;  // 144
  localparam V_DISPLAY_START = V_SYNC_PULSE + V_BACK_PORCH;  // 31

  wire clk_25MHz;
  wire enable_V_Counter;
  wire [15:0] H_Count_Value;
  wire [15:0] V_Count_Value;

  clock_divider clk_div (
    .clk_in(clk),
    .clk_out(clk_25MHz)
  );

  horizontal_counter VGA_Horiz (
    .clk_25MHz(clk_25MHz),
    .enable_V_Counter(enable_V_Counter),
    .H_Count_Value(H_Count_Value)
  );

  vertical_counter VGA_Verti (
    .clk_25MHz(clk_25MHz),
    .enable_V_Counter(enable_V_Counter),
    .V_Count_Value(V_Count_Value)
  );

  assign Hsync = (H_Count_Value < H_SYNC_PULSE) ? 1'b0 : 1'b1;
  assign Vsync = (V_Count_Value < V_SYNC_PULSE) ? 1'b0 : 1'b1;

  wire visible_area = (H_Count_Value >= H_DISPLAY_START && H_Count_Value < (H_DISPLAY_START + H_DISPLAY)) &&
                      (V_Count_Value >= V_DISPLAY_START && V_Count_Value < (V_DISPLAY_START + V_DISPLAY));

  wire [10:0] x = H_Count_Value - H_DISPLAY_START;
  wire [9:0]  y = V_Count_Value - V_DISPLAY_START;

  // Triangle parameters
  localparam TRI_HEIGHT = 100;
  localparam TRI_HALF_BASE = 75;

  reg [9:0] center_x = H_DISPLAY / 2;
  reg [9:0] center_y = V_DISPLAY / 2;

  // Movement logic
	reg [19:0] move_counter = 0;  // Smaller counter for faster movement

		always @(posedge clk_25MHz) begin
		  move_counter <= move_counter + 1;
		  if (move_counter[19]) begin   // Check MSB for slower repeat rate
			 move_counter <= 0;          // Reset counter after move
			 if (sw[0] && center_x > TRI_HALF_BASE + 1)  center_x <= center_x - 1;  // Left
			 if (sw[1] && center_x < (H_DISPLAY - TRI_HALF_BASE - 1)) center_x <= center_x + 1;  // Right
			 if (sw[2] && center_y > (TRI_HEIGHT / 2 + 1)) center_y <= center_y - 1;  // Up
			 if (sw[3] && center_y < (V_DISPLAY - TRI_HEIGHT / 2 - 1)) center_y <= center_y + 1;  // Down
		  end
		end

  wire [9:0] tip_y  = center_y - (TRI_HEIGHT / 2);
  wire [9:0] base_y = center_y + (TRI_HEIGHT / 2);

  wire in_bounds_y = (y >= tip_y) && (y <= base_y);
  wire signed [20:0] slope_mul = (y - tip_y) * TRI_HALF_BASE;
  wire signed [11:0] slope = (slope_mul * 26) >> 11;  // ~ /100

  wire signed [11:0] left_edge_x  = center_x - slope;
  wire signed [11:0] right_edge_x = center_x + slope;

  wire in_triangle = in_bounds_y && (x >= left_edge_x) && (x <= right_edge_x);

  assign Red   = visible_area ? (in_triangle ? 1'b0 : 1'b1) : 1'b0;
  assign Green = visible_area ? (in_triangle ? 1'b0 : 1'b1) : 1'b0;
  assign Blue  = visible_area ? (in_triangle ? 1'b0 : 1'b1) : 1'b0;

endmodule
