`timescale 1ns / 1ps

module CoinFSM (
    input clk,
    input frame,
    input [9:0] player_left,
    input [9:0] player_right,
    input [9:0] player_top,
    input [9:0] player_bottom,
    input reset,
    output [9:0] coin_x,
    output [9:0] coin_y,
    output coin_region,
    output coin_flash,
    output coin_collected,
    output [7:0] coin_count
);
    wire [1:0] Q, D;

    wire active_state = (Q != 2'b10); 
    
    wire coin_collected_next = coin_region & active_state & ~coin_collected;
    
FDRE coin_collected_ff (
    .C(clk), .R(reset | ~active_state), .CE(frame),
    .D(coin_collected_next),
    .Q(coin_collected)
);
    wire [9:0] x, x_next;
    wire [9:0] y, y_next;

    wire [7:0] rand;
    LFSR rand_gen (.clk(clk), .Q(rand));
    wire [9:0] random_y = 10'd192 + (rand % (10'd252 - 10'd192 + 1));

    wire [5:0] flash_counter;
    wire [5:0] flash_next = flash_counter + 1;
    wire flash_done = (flash_counter == 6'd60);

    FDRE flash_ff[5:0] (
        .C(clk), .R(reset), .CE(frame & (Q == 2'b10)),
        .D(flash_next),
        .Q(flash_counter)
    );

assign x_next = reset               ? 10'd640 :
                (Q == 2'b01 && x > 4) ? x - 4 :
                (Q == 2'b00)          ? 10'd640 :
                                       x;

assign y_next = reset ? random_y :
                (Q == 2'b00) ? random_y : y;
    FDRE x_ff[9:0] (.C(clk), .R(1'b0), .CE(frame), .D(x_next), .Q(x));
    FDRE y_ff[9:0] (.C(clk), .R(1'b0), .CE(frame), .D(y_next), .Q(y));
    assign coin_x = x;
    assign coin_y = y;

    assign coin_region = (x < player_right && (x + 10'd8) > player_left &&
                          y < player_bottom && (y + 10'd8) > player_top);

    assign coin_flash = (Q == 2'b10);

    assign D[0] = (Q == 2'b00 && x == 10'd640) ? 1'b1 :                // MOVING
                  ((Q == 2'b10 && flash_done) | (Q == 2'b01 && x_next <= 4)) ? 1'b0 : // HIDDEN
                  (Q == 2'b11) ? 1'b0 :                // bruh
                  Q[0];

    assign D[1] = (Q == 2'b01 && coin_region)  ? 1'b1 :                // FLASHING
                  ((Q == 2'b10 && flash_done) | (Q == 2'b01 && x_next <= 4)) ? 1'b0 :                // HIDDEN
                  Q[1];
    
    FDRE ff0 (.C(clk), .R(reset), .CE(frame), .D(D[0]), .Q(Q[0]));
    FDRE ff1 (.C(clk), .R(reset), .CE(frame), .D(D[1]), .Q(Q[1]));

    wire [7:0] count_reg, count_next;
    assign count_next = (Q == 2'b10) && flash_done ? count_reg + 1 : count_reg;
    
    FDRE #(.INIT(1'b0)) coin_count_ff[7:0] (.C(clk), .R(btnR), .CE(frame), .D(count_next), .Q(count_reg));
      
    assign coin_count = count_reg;
endmodule


