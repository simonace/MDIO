// ==================================================================
//                (C) COPYRIGHT Belling Co., Lmt.
//                      ALL RIGHTS RESERVED
// ==================================================================
//  File name         :  MDIO_controlpath.v
//  Author            :  Cheng Cai
//  File Initiation   :  2020-2-25
// ==================================================================


module MDIO_controlpath (
    // clk and reset
    input   wire            clk,
    input   wire            rstn,
    // soft reset
    input   wire            soft_reset,
    // data path interface
    input   wire            recent_rx_bit,
    input   wire            update_stage,
    input   wire            is_write,
    output  wire    [3:0]   mdio_out_cnt,
    output  wire            data_phase,
    output  wire            opcode_ready,
    output  wire            phyadr_ready,
    output  wire            devadr_ready,
    output  wire            data_ready,
    output  wire            mdio_oe
);

wire    [4:0]   cnt;
wire            cnt_clr;
wire            detecting_start;

// counter
MDIO_counter #(.CNT_WIDTH(5)) u_cnt(
    .clk            (clk),
    .rstn           (rstn),
    .soft_reset     (soft_reset),
    .enable         (update_stage),
    .clr            (cnt_clr),
    .cnt            (cnt)
);

assign mdio_out_cnt[3:0] = cnt[3:0];

assign detecting_start = (cnt=='d0) | (cnt=='d1);

// start detector
assign cnt_clr = detecting_start & recent_rx_bit;

// ready signals for registering segments of a frame
assign opcode_ready = (cnt=='d3);
assign phyadr_ready = (cnt=='d8);
assign devadr_ready = (cnt=='d13);
assign data_ready = &cnt;
assign data_phase = cnt[4];
//output enable TA2 and read
assign mdio_oe = ~is_write & ((cnt=='d15) | data_phase);

endmodule
