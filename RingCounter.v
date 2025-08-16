`timescale 1ns / 1ps


module RingCounter(
    input clk,
    input digsel,
    output [3:0] q
    );
    wire [3:0] result;
    
    FDRE #(.INIT(1'b1)) Q0_FF (.C(clk), .R(1'b0), .CE(digsel), .D(result[3]), .Q(result[0]));
    FDRE #(.INIT(1'b0)) Q1_FF (.C(clk), .R(1'b0), .CE(digsel), .D(result[0]), .Q(result[1]));
    FDRE #(.INIT(1'b0)) Q2_FF (.C(clk), .R(1'b0), .CE(digsel), .D(result[1]), .Q(result[2]));
    FDRE #(.INIT(1'b0)) Q3_FF (.C(clk), .R(1'b0), .CE(digsel), .D(result[2]), .Q(result[3]));
    assign q = result;
endmodule
