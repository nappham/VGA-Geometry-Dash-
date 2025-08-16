`timescale 1ns / 1ps

module Syncs(
    input [9:0] hcount,
    input [9:0] vcount,
    output Hsync,
    output Vsync,
    output video_on
);
    assign Hsync = ~(hcount >= 656 && hcount < 752);
    assign Vsync = ~(vcount >= 490 && vcount < 492);
    assign video_on = (hcount < 640 && vcount < 480);
endmodule