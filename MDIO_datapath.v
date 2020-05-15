// ==================================================================
//                (C) COPYRIGHT Belling Co., Lmt.
//                      ALL RIGHTS RESERVED
// ==================================================================
//  File name         :  MDIO_datapath.v
//  Author            :  Cheng Cai
//  File Initiation   :  2020-2-24
// ==================================================================


module MDIO_datapath (
    // clk and reset
    input   wire            clk, 
    input   wire            rstn,
    // MDIO interface
    input   wire            MDIO_in,
    output  wire             MDIO_out,
    input   wire            MDC,
    // control path interface
    output  reg     [15:0]  shift_reg_window,
    input   wire            data_phase,
    input   wire            is_write,
    output  reg             update_stage,
    output  reg             register_stage,
    input   wire    [3:0]   mdio_out_cnt,
    // MDIO TXD
    input   wire    [15:0]  mdio_txd, 
    //soft reset
    input   wire            soft_reset
);

reg             mdio_sampled_data;
reg             mdc_synch_stage1;
reg             mdc_synched_data;           //mdc_synch_stage2
reg             mdc_synched_data_shift;
wire            mdc_posedge;          

// sample FF
always @(posedge MDC) begin
    mdio_sampled_data <= MDIO_in;
end

// MDC synch
always @(posedge clk or negedge rstn) begin
    if (~rstn) begin
        mdc_synch_stage1 <= 1'b0;
        mdc_synched_data <= 1'b0;
        mdc_synched_data_shift <= 1'b0;
    end
    else if (soft_reset) begin
        mdc_synch_stage1 <= 1'b0;
        mdc_synched_data <= 1'b0;
        mdc_synched_data_shift <= 1'b0;
    end
    else begin
        mdc_synch_stage1 <= MDC;
        mdc_synched_data <= mdc_synch_stage1;
        mdc_synched_data_shift <= mdc_synched_data;
    end
end

// mdc_posedge detected
assign mdc_posedge = (~mdc_synched_data_shift) & mdc_synched_data;

// update_stage/register_stage
always @(posedge clk or negedge rstn) begin
    if (~rstn) begin
        update_stage <= 1'b0;
        register_stage <= 1'b0;
    end
    else if (soft_reset) begin
        update_stage <= 1'b0;
        register_stage <= 1'b0;
    end
    else begin
        update_stage <= mdc_posedge;
        register_stage <= update_stage;
    end
end

// shift reg
always @(posedge clk or negedge rstn) begin
    if (~rstn) begin
        shift_reg_window[15:0] <= 16'b0000_0000_0001_1111;
    end
    else if (soft_reset) begin
        shift_reg_window[15:0] <= 16'b0000_0000_0001_1111;
    end
    else if (mdc_posedge) begin
        shift_reg_window[0] <= mdio_sampled_data;
        shift_reg_window[4:1] <= shift_reg_window[3:0];
        if (data_phase & is_write) begin
            shift_reg_window[15:5] <= shift_reg_window[14:4];
        end
    end
end

// MDIO_out
assign MDIO_out = ~is_write & data_phase & mdio_txd[15-mdio_out_cnt];


endmodule
