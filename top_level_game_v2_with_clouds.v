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

  localparam H_DISPLAY_START = H_SYNC_PULSE + H_BACK_PORCH;
  localparam V_DISPLAY_START = V_SYNC_PULSE + V_BACK_PORCH;

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

  // Triangle (plane) parameters
  localparam TRI_HEIGHT = 100;
  localparam TRI_HALF_BASE = 75;

  reg [9:0] center_x = H_DISPLAY / 2;
  reg [9:0] center_y = V_DISPLAY / 2;

  // Movement logic
  reg [19:0] move_counter = 0;

  always @(posedge clk_25MHz) begin
    move_counter <= move_counter + 1;
    if (move_counter[19]) begin
      move_counter <= 0;
      if (sw[0] && center_x > TRI_HALF_BASE + 1)                 center_x <= center_x - 1;
      if (sw[1] && center_x < (H_DISPLAY - TRI_HALF_BASE - 1))   center_x <= center_x + 1;
      if (sw[2] && center_y > (TRI_HEIGHT / 2 + 1))              center_y <= center_y - 1;
      if (sw[3] && center_y < (V_DISPLAY - TRI_HEIGHT / 2 - 1))  center_y <= center_y + 1;
    end
  end

  // Triangle rendering
  wire [9:0] tip_y  = center_y - (TRI_HEIGHT / 2);
  wire [9:0] base_y = center_y + (TRI_HEIGHT / 2);

  wire in_bounds_y = (y >= tip_y) && (y <= base_y);
  wire signed [20:0] slope_mul = (y - tip_y) * TRI_HALF_BASE;
  wire signed [11:0] slope = (slope_mul * 26) >> 11;

  wire signed [11:0] left_edge_x  = center_x - slope;
  wire signed [11:0] right_edge_x = center_x + slope;

  wire in_triangle = in_bounds_y && (x >= left_edge_x) && (x <= right_edge_x);

  // Mountain rendering
  wire [9:0] mountain_center = H_DISPLAY / 2;
  wire [17:0] dx = (x > mountain_center) ? (x - mountain_center) : (mountain_center - x);
  wire [9:0] hill_top = V_DISPLAY / 2 + 50;
  wire [17:0] curve = (dx * dx) >> 10;
  wire [9:0] y_parabola = hill_top + curve[9:0];
  wire in_mountain = (y >= y_parabola);

  // Cloud animation logic
  reg [9:0] cloud_offset = 0;
  always @(posedge clk_25MHz) begin
    cloud_offset <= (cloud_offset < H_DISPLAY - 1) ? cloud_offset + 1 : 0;
  end

// Cloud 1 (Center) shape logic
localparam CLOUD_RADIUS = 10;
wire in_cloud1 = ((x - 100)*(x - 100) + (y - 80)*(y - 80) < (CLOUD_RADIUS * CLOUD_RADIUS));
wire in_cloud2 = ((x - 115)*(x - 115) + (y - 75)*(y - 75) < (CLOUD_RADIUS * CLOUD_RADIUS));
wire in_cloud3 = ((x - 130)*(x - 130) + (y - 80)*(y - 80) < (CLOUD_RADIUS * CLOUD_RADIUS));
wire in_cloud4 = ((x - 115)*(x - 115) + (y - 90)*(y - 90) < (CLOUD_RADIUS * CLOUD_RADIUS));
wire in_cloud = in_cloud1 || in_cloud2 || in_cloud3 || in_cloud4;

// Cloud 2 (Upper Left)
localparam CLOUD_RADIUS2 = 10;
wire in_cloud_left_1 = ((x - 50)*(x - 50) + (y - 60)*(y - 60) < (CLOUD_RADIUS2 * CLOUD_RADIUS2));
wire in_cloud_left_2 = ((x - 65)*(x - 65) + (y - 55)*(y - 55) < (CLOUD_RADIUS2 * CLOUD_RADIUS2));
wire in_cloud_left_3 = ((x - 80)*(x - 80) + (y - 60)*(y - 60) < (CLOUD_RADIUS2 * CLOUD_RADIUS2));
wire in_cloud_left_4 = ((x - 65)*(x - 65) + (y - 70)*(y - 70) < (CLOUD_RADIUS2 * CLOUD_RADIUS2));
wire in_cloud_left = in_cloud_left_1 || in_cloud_left_2 || in_cloud_left_3 || in_cloud_left_4;

// Cloud 3 (Upper Right)
localparam CLOUD_RADIUS3 = 10;
wire in_cloud_right_1 = ((x - 540)*(x - 540) + (y - 60)*(y - 60) < (CLOUD_RADIUS3 * CLOUD_RADIUS3));
wire in_cloud_right_2 = ((x - 555)*(x - 555) + (y - 55)*(y - 55) < (CLOUD_RADIUS3 * CLOUD_RADIUS3));
wire in_cloud_right_3 = ((x - 570)*(x - 570) + (y - 60)*(y - 60) < (CLOUD_RADIUS3 * CLOUD_RADIUS3));
wire in_cloud_right_4 = ((x - 555)*(x - 555) + (y - 70)*(y - 70) < (CLOUD_RADIUS3 * CLOUD_RADIUS3));
wire in_cloud_right = in_cloud_right_1 || in_cloud_right_2 || in_cloud_right_3 || in_cloud_right_4;


 assign Red   = visible_area ? (in_cloud || in_cloud_left || in_cloud_right) : 1'b0;

assign Green = visible_area ?
                (in_cloud || in_cloud_left || in_cloud_right ? 1'b1 :
                 in_triangle ? 1'b0 :
                 in_mountain ? 1'b1 : 1'b1) : 1'b0;

assign Blue  = visible_area ?
                (in_cloud || in_cloud_left || in_cloud_right ? 1'b1 :
                 in_triangle ? 1'b0 :
                 in_mountain ? 1'b0 : 1'b1) : 1'b0;


endmodule
