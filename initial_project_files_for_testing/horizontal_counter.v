`timescale 1ns / 1ps

module horizontal_counter (
    input  wire clk_25MHz,
    output reg  enable_V_Counter,
    output reg [15:0] H_Count_Value
);

  always @(posedge clk_25MHz) begin
    if (H_Count_Value < 799) begin
      H_Count_Value <= H_Count_Value + 1;
      enable_V_Counter <= 0;
    end else begin
      H_Count_Value <= 0; // Reset horizontal counter
      enable_V_Counter <= 1; // Trigger vertical counter
    end
  end

  // Initialize the output registers (good practice)
  initial begin
    enable_V_Counter = 0;
    H_Count_Value = 0;
  end

endmodule
