// ==================================================================
//                (C) COPYRIGHT Belling Co., Lmt.
//                      ALL RIGHTS RESERVED
// ==================================================================
//  File name         :  MDIO_top.v
//  Author            :  Cheng Cai
//  File Initiation   :  2020-2-24
// ==================================================================


module MDIO_top (
    // MDIO interface
    input   wire            MDIO_in,
    output  wire            MDIO_out,
    input   wire            MDC,
    input   wire    [4:0]   PRTADR,
    // APB interface
    input   wire            PCLK,
//    input   wire            PCLKG,
    input   wire            PRESETn,
    input   wire            PSEL,
    input   wire            PENABLE,
    input   wire            PWRITE,
    input   wire    [9:0]   PADDR,
    input   wire    [31:0]  PWDATA,
    output  wire    [31:0]  PRDATA,
    // System interface
    output  wire            mdio_oe,
    output  wire            MDIO_irq
);

wire    [15:0]  shift_reg;
wire            update_stage;
wire            register_stage;
wire            data_phase;
wire            opcode_ready;
wire            phyadr_ready;
wire            devadr_ready;
wire            soft_reset;
wire            is_write;
wire    [3:0]   mdio_out_cnt;
wire    [15:0]  mdio_txd;

MDIO_datapath u_mdio_datapath (
  .clk                      (PCLK),
  .rstn                     (PRESETn),
  .MDIO_in                  (MDIO_in),
  .MDIO_out                 (MDIO_out),
  .MDC                      (MDC),
  .shift_reg_window         (shift_reg),
  .data_phase               (data_phase),
  .is_write                 (is_write),
  .update_stage             (update_stage),
  .register_stage           (register_stage),
  .mdio_out_cnt             (mdio_out_cnt),
  .mdio_txd                 (mdio_txd),
  .soft_reset               (soft_reset)
);

MDIO_controlpath u_mdio_controlpath (
   .clk                     (PCLK),
   .rstn                    (PRESETn),
   .soft_reset              (soft_reset),
   .recent_rx_bit           (shift_reg[0]),
   .update_stage            (update_stage),
   .is_write                (is_write),
   .mdio_out_cnt            (mdio_out_cnt),
   .data_phase              (data_phase),
   .opcode_ready            (opcode_ready),
   .phyadr_ready            (phyadr_ready),
   .devadr_ready            (devadr_ready),
   .data_ready              (data_ready),
   .mdio_oe                 (mdio_oe)
);

MDIO_reg u_reg (
    .PCLK                   (PCLK),
    //.PCLKG                  (PCLKG),
    .PRESETn                (PRESETn),
    .PSEL                   (PSEL),
    .PENABLE                (PENABLE),
    .PWRITE                 (PWRITE),
    .PADDR                  (PADDR),
    .PWDATA                 (PWDATA),
    .PRDATA                 (PRDATA),
    .shift_reg_window       (shift_reg[15:0]), 
    .mdio_txd               (mdio_txd),
    .register_stage         (register_stage),
    .opcode_ready           (opcode_ready),
    .phyadr_ready           (phyadr_ready),
    .devadr_ready           (devadr_ready),
    .data_ready             (data_ready),
    .is_write               (is_write),
    .PRTADR                 (PRTADR),
    .irq                    (MDIO_irq),
    .soft_reset             (soft_reset)
);

endmodule
