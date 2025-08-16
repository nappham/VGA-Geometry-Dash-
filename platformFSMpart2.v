`timescale 1ns / 1ps

module platformFSMpart2 (
    input clk,
    input frame,
    input reset,
    input stop,
    input start,
    output [9:0] x_left,
    output [9:0] x_right,
    output over_hole
);

    wire [9:0] left, left_next;
    wire [9:0] right, right_next;

    wire [7:0] rand;
    LFSR lfsr_gen (.clk(clk), .Q(rand));

    wire [2:0] new_width = (rand[7:6] % 3'd3) + 3'd4;
    wire [2:0] hole_width_reg;
    wire [2:0] hole_width = hole_width_reg;

    wire reset_hole = (right <= 10'd1);
    wire update = reset_hole & frame;

    wire [2:0] width_in;
    assign width_in = reset ? 3'd4 : new_width;
    
    FDRE width_ff0 (.C(clk), .R(1'b0), .CE(update), .D(width_in[0]), .Q(hole_width_reg[0]));
    FDRE width_ff1 (.C(clk), .R(1'b0), .CE(update), .D(width_in[1]), .Q(hole_width_reg[1]));
    FDRE width_ff2 (.C(clk), .R(1'b0), .CE(update), .D(width_in[2]), .Q(hole_width_reg[2]));

//    assign left_next  = ~start || stop ? left  : reset_hole ? 10'd640 : left <= 10'd1 ? left : left - 1;
//    assign right_next = ~start || stop ? right : reset_hole ? (10'd640 + hole_width * 10) : right - 1;

    assign left_next  = ~start || stop ? left  :
                        reset ? 10'd640 :
                        reset_hole ? 10'd640 :
                        left <= 10'd1 ? left : left - 1;
    
    assign right_next = ~start || stop ? right :
                        reset ? (10'd640 + hole_width * 10) :
                        reset_hole ? (10'd640 + hole_width * 10) :
                        right - 1;
                    
    FDRE x_ff[9:0] (.C(clk), .R(1'b0), .CE(frame), .D(left_next), .Q(left));
    FDRE y_ff[9:0] (.C(clk), .R(1'b0), .CE(frame), .D(right_next), .Q(right));

    assign x_left = left;
    assign x_right = right;
    
    //For falling
    wire [9:0] player_left  = 10'd100;
    wire [9:0] player_right = 10'd115;
    assign over_hole = (player_right - 11 > x_left) && (player_left + 11 < x_right);

endmodule