`timescale 1ns / 1ps
module top (
    input wire clk,
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

  // Calculated Ranges
  localparam H_DISPLAY_START = H_SYNC_PULSE + H_BACK_PORCH;               // 144
  localparam H_DISPLAY_END   = H_DISPLAY_START + H_DISPLAY;               // 784

  localparam V_DISPLAY_START = V_SYNC_PULSE + V_BACK_PORCH;               // 31
  localparam V_DISPLAY_END   = V_DISPLAY_START + V_DISPLAY;               // 511

  // Internal wires
  wire clk_25MHz;
  wire enable_V_Counter;
  wire [15:0] H_Count_Value;
  wire [15:0] V_Count_Value;

  // Instantiate Modules
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

  // Hsync and Vsync (active low)
  assign Hsync = (H_Count_Value < H_SYNC_PULSE) ? 1'b0 : 1'b1;
  assign Vsync = (V_Count_Value < V_SYNC_PULSE) ? 1'b0 : 1'b1;

  // Visible area logic
  wire visible_area = (H_Count_Value >= H_DISPLAY_START && H_Count_Value < H_DISPLAY_END) &&
                      (V_Count_Value >= V_DISPLAY_START && V_Count_Value < V_DISPLAY_END);

  // Pixel coordinates relative to display
  wire [10:0] x = H_Count_Value - H_DISPLAY_START;
  wire [9:0]  y = V_Count_Value - V_DISPLAY_START;

  // Triangle center and dimensions
  localparam CENTER_X      = H_DISPLAY / 2;       // 320
  localparam CENTER_Y      = V_DISPLAY / 2;       // 240
  localparam TRI_HEIGHT    = 100;
  localparam TRI_HALF_BASE = 75;

  wire [9:0] tip_y  = CENTER_Y - (TRI_HEIGHT / 2);
  wire [9:0] base_y = CENTER_Y + (TRI_HEIGHT / 2);

  // Only consider pixels in vertical range of triangle
  wire in_bounds_y = (y >= tip_y) && (y <= base_y);

  // Approximate (y - tip_y) * TRI_HALF_BASE / TRI_HEIGHT
  wire signed [20:0] slope_mul = (y - tip_y) * TRI_HALF_BASE;
  wire signed [11:0] slope = (slope_mul * 26) >> 11;  // ~ divide by 100

  wire signed [11:0] left_edge_x  = CENTER_X - slope;
  wire signed [11:0] right_edge_x = CENTER_X + slope;

  wire in_triangle = in_bounds_y && (x >= left_edge_x) && (x <= right_edge_x);

  // Color logic: black triangle in white background
   assign Red   = visible_area ? (in_triangle ? 1'b0 : 1'b1) : 1'b0;
	assign Green = visible_area ? (in_triangle ? 1'b0 : 1'b1) : 1'b0;
	assign Blue  = visible_area ? (in_triangle ? 1'b0 : 1'b1) : 1'b0;


endmodule
