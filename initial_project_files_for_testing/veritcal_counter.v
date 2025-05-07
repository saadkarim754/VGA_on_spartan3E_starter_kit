`timescale 1ns / 1ps

module vertical_counter (
    input  wire clk_25MHz,
    input  wire enable_V_Counter,
    output reg [15:0] V_Count_Value = 0
);

  always @(posedge clk_25MHz) begin
    if (enable_V_Counter == 1'b1) begin
      if (V_Count_Value < 520) begin
        V_Count_Value <= V_Count_Value + 1;
      end else begin
        V_Count_Value <= 0; // Reset vertical counter
      end
    end
  end

endmodule
