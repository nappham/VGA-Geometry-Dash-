`timescale 1ns / 1ps

module LFSR(
    input clk,
    output [7:0] Q
    );
    
    wire [7:0] rnd;
    wire XOR;
    
   assign XOR = rnd[0] ^ rnd[5] ^ rnd[6] ^ rnd[7];
   FDRE #(.INIT(1)) LFSRff0 (.C(clk), .R(0), .CE(1), .D(XOR), .Q(rnd[0]));
   FDRE #(.INIT(1)) LFSRff1 (.C(clk), .R(0), .CE(1), .D(rnd[0]), .Q(rnd[1]));
   FDRE #(.INIT(1)) LFSRff2 (.C(clk), .R(0), .CE(1), .D(rnd[1]), .Q(rnd[2]));
   FDRE #(.INIT(1)) LFSRff3 (.C(clk), .R(0), .CE(1), .D(rnd[2]), .Q(rnd[3]));
   FDRE #(.INIT(1)) LFSRff4 (.C(clk), .R(0), .CE(1), .D(rnd[3]), .Q(rnd[4]));
   FDRE #(.INIT(1)) LFSRff5 (.C(clk), .R(0), .CE(1), .D(rnd[4]), .Q(rnd[5]));
   FDRE #(.INIT(1)) LFSRff6 (.C(clk), .R(0), .CE(1), .D(rnd[5]), .Q(rnd[6]));
   FDRE #(.INIT(1)) LFSRff7 (.C(clk), .R(0), .CE(1), .D(rnd[6]), .Q(rnd[7]));
   
   assign Q = rnd;
endmodule

