`timescale 1ns / 1ps

module clock_divider (
    input wire clk_in,   // 50 MHz input clock
    output reg clk_out   // 25 MHz output clock
);
    always @(posedge clk_in) begin
        clk_out <= ~clk_out;
    end
endmodule
