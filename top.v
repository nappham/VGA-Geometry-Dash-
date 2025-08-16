`timescale 1ns / 1ps

module top (
    input clkin,          
    input btnR,          
    input btnU,   
    input btnC,
    input btnL,
    input [4:0] sw,      
    output [3:0] vgaRed,
    output [3:0] vgaGreen,
    output [3:0] vgaBlue,
    output Hsync,
    output Vsync,
    output [15:0] led,
    output [6:0] seg,
    output [3:0] an

);

    wire [7:0] rand;
    LFSR lfsr (.clk(clk), .Q(rand));

    wire clk, digsel;
    wire [9:0] hcount, vcount;
    wire video_on;
    labVGA_clks clk_gen (.clkin(clkin), .greset(btnR), .clk(clk), .digsel(digsel));
    PixelAddress address_gen (.clk(clk), .hcount(hcount), .vcount(vcount));
    Syncs vga_sync (.hcount(hcount), .vcount(vcount), .Hsync(Hsync), .Vsync(Vsync), .video_on(video_on));
    wire vsync_delayed, frame;
    FDRE vsync_ff (.C(clk), .R(1'b0), .CE(1'b1), .D(Vsync), .Q(vsync_delayed));
    assign frame = vsync_delayed & ~Vsync; 

    wire start;
    FDRE #(.INIT(1'b0)) starting (.C(clk), .R(1'b0), .CE(btnC), .D(1'b1), .Q(start));
    
    //platform logic
    wire in_platform_row = (vcount >= 320 && vcount < 336);
    wire in_platform_col = (hcount >= 8 && hcount < 632);
    wire hardcoded_platform = in_platform_row && in_platform_col;  
    
    wire [9:0] x_left, x_right;
    wire over_hole;
    platformFSMpart2 please (.clk(clk), .frame(frame), .stop(lost || ~alive), .reset(reset), .start(start), .x_left(x_left), .x_right(x_right), .over_hole(over_hole));
    wire hole_region = (hcount >= x_left && hcount <= x_right) && (vcount >= 320 && vcount < 336);
      
    // Player + Power Bar Logic
    wire lost;
    wire [9:0] player_y;
    wire [6:0] power_height;
    wire [1:0] state;  
    wire on_platform = (player_y >= 303); 
    wire power_bar_region = (hcount >= 32 && hcount < 48) && (vcount >= (96 - power_height) && vcount < 96);      
    jumpFSM jumper (.clk(clk), .frame(frame), .reset(reset), .alive(alive) ,.btnU(btnU), .on_platform(on_platform), .over_hole(over_hole), .player_y(player_y), .power_height(power_height), .state(state), .lost(lost));
    wire [9:0] player_left   = 100;
    wire [9:0] player_right  = 115;
    wire [9:0] player_top    = player_y;
    wire [9:0] player_bottom = player_y + 15;
    
    wire player_region = (hcount >= player_left  && hcount <= player_right) &&
                         (vcount >= player_top   && vcount <= player_bottom);

    wire top_border    = (vcount < 8);
    wire bottom_border = (vcount >= 472);
    wire left_border   = (hcount < 8);
    wire right_border  = (hcount >= 632);
    wire draw_border   = top_border || bottom_border || left_border || right_border;

    // Coin Logic
    wire [9:0] coin_x;
    wire [9:0] coin_y;
    wire coin_region;
    wire testcoin_region = (hcount >= coin_x) && (hcount < coin_x + 10) &&
                           (vcount >= coin_y) && (vcount < coin_y + 10);
    wire coin_flash;
    wire coin_collected;
    wire [1:0] stateCoin;
    CoinFSM coin_module (.clk(clk), .frame(start & frame), .reset(reset), .player_left(player_left), .player_right(player_right), .player_top(player_top), .player_bottom(player_bottom), .coin_x(coin_x), .coin_y(coin_y), .coin_region(coin_region), .coin_flash(coin_flash), .coin_collected(coin_collected), .coin_count(coin_count));

    wire [23:0] flash_counter;
    wire flash_toggle;
    wire [23:0] flash_counter_next = flash_counter + 1;
    assign flash_toggle = flash_counter[23];
    FDRE flash_count_ff[23:0] (
        .C(clk), .R(1'b0), .CE(1'b1),
        .D(flash_counter_next),
        .Q(flash_counter)
    );

    wire [7:0] coin_count;

    wire [3:0] sel, H;
    wire [15:0] N = {switch_count, 4'b0101, coin_count};
    RingCounter ring(.clk(clk), .digsel(digsel), .q(sel));
    selector select(.N(N), .sel(sel), .H(H));
    hex7seg display (.n(H), .seg(seg));
    assign an[0] = ~sel[0];
    assign an[1] = ~sel[1];
    assign an[2] = 1'b1;
    assign an[3] = ~(sel[3] && multiplayer);

    wire [3:0] player_r, player_g, player_b;
    wire [3:0] next_r = rand[3:0];
    wire [3:0] next_g = rand[7:4];
    wire [3:0] next_b = {rand[5], rand[2], rand[1], rand[0]}; 
    FDRE #(.INIT(1'b1)) r_ff[3:0] (.C(clk), .R(1'b0), .CE(coin_collected), .D(next_r), .Q(player_r));
    FDRE #(.INIT(1'b1)) g_ff[3:0] (.C(clk), .R(1'b0), .CE(coin_collected), .D(next_g), .Q(player_g));
    FDRE #(.INIT(1'b1)) b_ff[3:0] (.C(clk), .R(1'b0), .CE(coin_collected), .D(next_b), .Q(player_b));

    //EC #2
    wire challenge;
    wire [3:0] switch_sum;
    wire alive = ~((switch_count == 0) && multiplayer);
    FDRE #(.INIT(1'b0)) lives (.C(clk), .R(1'b0), .CE(btnL), .D(1'b1), .Q(challenge));
//    assign led[0] = challenge;
//    assign led[1] = alive;
//    assign led[2] = multiplayer;
//    assign led[3] = lost;
//    assign led[4] = flash_toggle;
//    assign led[5] = reset;
    wire multiplayer = start && challenge;
    assign led[15] = (switch_count >= 1);
    assign led[14] = (switch_count >= 2);
    assign led[13] = (switch_count >= 3);
    assign led[12] = (switch_count >= 4);
    assign led[11] = (switch_count >= 5);
    assign switch_sum  = sw[0] + sw[1] + sw[2] + sw[3] + sw[4];
    
    wire reset = btnC && alive && multiplayer && lost;
    
    wire lost_prev;
    FDRE #(.INIT(1'b0)) lost_reg (.C(clk), .R(1'b0), .CE(1'b1), .D(lost), .Q(lost_prev));
    
    wire lost_rising = lost & ~lost_prev;
    
    wire [3:0] switch_count;
    wire [3:0] switch_sum;
    assign switch_sum = sw[0] + sw[1] + sw[2] + sw[3] + sw[4];
    
    wire reset_switch_count = ~start;
    wire subtract = lost_rising && (|switch_count);
    wire reset_switch_count = ~start;
    wire [3:0] switch_next;
    assign switch_next = reset_switch_count ? switch_sum :
                         subtract            ? switch_count - 1 :
                                                switch_count;    
                                                
    FDRE #(.INIT(1'b0)) sc0 (.C(clk), .R(1'b0), .CE(1'b1), .D(switch_next[0]), .Q(switch_count[0]));
    FDRE #(.INIT(1'b0)) sc1 (.C(clk), .R(1'b0), .CE(1'b1), .D(switch_next[1]), .Q(switch_count[1]));
    FDRE #(.INIT(1'b0)) sc2 (.C(clk), .R(1'b0), .CE(1'b1), .D(switch_next[2]), .Q(switch_count[2]));
    FDRE #(.INIT(1'b0)) sc3 (.C(clk), .R(1'b0), .CE(1'b1), .D(switch_next[3]), .Q(switch_count[3]));

    assign vgaRed   = (video_on && draw_border)     ? 4'hF :
                      (video_on && player_region) && ((~lost && alive) | flash_toggle)   ? player_r :
                      (video_on && testcoin_region && (~coin_flash | flash_toggle))  ? 4'hF :
                      (video_on && hardcoded_platform && (~hole_region || ~start)) ? 4'hF: 4'h0;

    assign vgaGreen = (video_on && player_region) && ((~lost && alive) | flash_toggle)   ? player_g :
                      (video_on && power_bar_region) ? 4'hF :
                      (video_on && testcoin_region && (~coin_flash | flash_toggle))  ? 4'hF :
                      (video_on && hardcoded_platform && (~hole_region || ~start)) ? 4'hF: 4'h0;

    assign vgaBlue  = (video_on && testcoin_region && (~coin_flash | flash_toggle))  ? 4'h0 :
                      (video_on && player_region) && ((~lost && alive) | flash_toggle)   ? player_b :
                      (hardcoded_platform && (~hole_region || ~start)) ? 4'hF: 4'h0;

endmodule

