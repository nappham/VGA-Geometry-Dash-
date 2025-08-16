`timescale 1ns / 1ps

module PixelAddress (
    input clk,
    output [9:0] hcount,
    output [9:0] vcount
);

    wire [9:0] h, h_next;
    wire [9:0] v, v_next;

    wire hreset = (h == 10'd799);
    wire vreset = (v == 10'd524);

    assign h_next = hreset ? 10'd0 : h + 1;

    assign v_next = (hreset && vreset) ? 10'd0 :
                    (hreset)           ? v + 1 :
                                         v;

    FDRE h_ff[9:0] (
        .C(clk), .CE(1'b1), .R(hreset), .D(h_next), .Q(h)
    );

    FDRE v_ff[9:0] (
        .C(clk), .CE(hreset), .R(vreset), .D(v_next), .Q(v)
    );

    assign hcount = h;
    assign vcount = v;

endmodule
