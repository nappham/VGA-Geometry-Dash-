`timescale 1ns / 1ps

module jumpFSM (
    input clk,
    input frame,
    input reset,
    input alive,
    input btnU,
    input on_platform,
    input over_hole,
    output [6:0] power_height,
    output [9:0] player_y,
    output [1:0] state,
    output lost
);

    // 00: REST, 01: ASCEND, 10: DESCEND
    wire [1:0] Q, D;
    wire [6:0] power, power_next;
    assign power_height = power;
    wire power_max = (power == 7'd64);
    wire power_min = (power == 7'd0);
    
    assign power_next = (Q == 2'b00 && btnU && ~power_max && y <= 10'd303 && alive) ? (power + 1) :
                        (Q == 2'b01 && ~power_min) ? (power - 1) :power;

    FDRE power_ff[6:0] (.C(clk), .R(reset), .CE(frame), .D(power_next), .Q(power));
    

    wire [9:0] y, y_next;
    assign player_y = y;
    assign lost = y >= 455;
    assign y_next =
        (over_hole && on_platform && y < 455) ? (y + 2) :
        (Q == 2'b01) ? (y - 2) :
        (y > 303 && y < 455) ? y + 2 :
        (y >= 455) ? y :
        (Q == 2'b10 && ~on_platform)    ? (y + 2) :
        (Q == 2'b00) ? 10'd303 : y;

    FDRE y_ff[9:0] (.C(clk), .R(reset), .CE(frame), .D(y_next), .Q(y));
    
    assign D[0] = (Q == 2'b00 && ~btnU && power > 0) ? 1'b1 :  // ASCEND
                  ((Q == 2'b10 && on_platform) || lost)               ? 1'b0 :  // REST
                  (Q == 2'b11) ? 1'b0 : // Wow this actually worked???? 
                                                             Q[0];

    assign D[1] = (Q == 2'b01 && power_min)                 ? 1'b1 :  // DESCEND
                  (Q == 2'b10 && on_platform)               ? 1'b0 :  // REST
                                                             Q[1];

    FDRE #(.INIT(1'b0)) ff_state0 (.C(clk), .R(reset), .CE(frame), .D(D[0]), .Q(Q[0]));
    FDRE #(.INIT(1'b0)) ff_state1 (.C(clk), .R(reset), .CE(frame), .D(D[1]), .Q(Q[1]));
    assign state[1] = Q[1];
    assign state[0] = Q[0]; 
endmodule