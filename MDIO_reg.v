// ==================================================================
//                (C) COPYRIGHT Belling Co., Lmt.
//                      ALL RIGHTS RESERVED
// ==================================================================
//  File name         :  MDIO_reg.v
//  Author            :  Cheng Cai
//  File Initiation   :  2020-2-25
// ==================================================================


module MDIO_reg (
    // APB interface 
    input   wire            PCLK,
    //input   wire            PCLKG,
    input   wire            PRESETn,
    input   wire            PSEL,
    input   wire            PENABLE,
    input   wire            PWRITE,
    input   wire    [9:0]   PADDR,
    input   wire    [31:0]  PWDATA,
    output  reg     [31:0]  PRDATA,
    // register window
    input   wire    [15:0]  shift_reg_window,
    // MDIO TXD
    output  wire    [15:0]  mdio_txd,
    // control signals
    input   wire            register_stage,
    input   wire            opcode_ready,
    input   wire            phyadr_ready,
    input   wire            devadr_ready,
    input   wire            data_ready,
    output  wire            is_write,
    // PHYADR from port
    input   wire    [4:0]   PRTADR,
    // irq
    output  wire            irq,
    // soft reset (out)
    output  reg             soft_reset

);

wire            w_en;
wire            r_en;
wire            higher_addr_match;
wire            MDCON_addr_match;
//wire            MDFRM_addr_match;
//wire            MDRXD_addr_match;
//wire            MDADR_addr_match;
wire            MDTXD_addr_match;
wire            MDPHY_addr_match;
wire            MDSTA_addr_match;
wire            MDIEN_addr_match;
//wire            MDPIN_addr_match;

reg             MD_DRV;
reg             MD_PHY_WIDTH;
reg     [1:0]   MD_OP;
wire            op_is_addr;
wire            op_is_write;
wire            op_is_read;
wire            op_is_incr;
reg     [4:0]   MD_PHY;
reg     [4:0]   MD_DEV;
reg     [15:0]  MD_RXD;
reg     [15:0]  MD_ADR;
reg     [15:0]  MD_TXD;
reg     [4:0]   MD_DEVADD;
reg     [4:0]   MD_PHYSEL;
reg     [4:0]   MD_PHYSW;
reg             MD_WRF;
reg             MD_ADRF;
reg             MD_INCF;
reg             MD_RDF;
reg             MD_DEVM;
reg             MD_DEVN;
reg             MD_PHYM;
reg             MD_PHYN;
wire            sta_rd_clr;
reg             sta_rd;
wire    [4:0]   MD_PHYADD;
reg             phyadr_compare_stage;
reg             devadr_compare_stage;
wire            phyadr_match;
wire            devadr_match;
wire            bothadr_match;
reg             MD_WRFI;
reg             MD_ADRI;
reg             MD_INCFI;
reg             MD_RDFI;
reg             MD_DEVMI;
reg             MD_DEVNI;
reg             MD_PHYMI;
reg             MD_PHYNI;

assign w_en = PWRITE & PSEL & PENABLE;
assign r_en = (~PWRITE) & PSEL & PENABLE;
assign higher_addr_match = (PADDR[9:6]==4'h0);
assign MDCON_addr_match = higher_addr_match & (PADDR[5:2]==4'h0);
//assign MDFRM_addr_match = higher_addr_match & (PADDR[5:2]==4'h1);
//assign MDRXD_addr_match = higher_addr_match & (PADDR[5:2]==4'h2);
//assign MDADR_addr_match = higher_addr_match & (PADDR[5:2]==4'h3);
assign MDTXD_addr_match = higher_addr_match & (PADDR[5:2]==4'h4);
assign MDPHY_addr_match = higher_addr_match & (PADDR[5:2]==4'h5);
assign MDSTA_addr_match = higher_addr_match & (PADDR[5:2]==4'h6);
assign MDIEN_addr_match = higher_addr_match & (PADDR[5:2]==4'h7);
//assign MDPIN_addr_match = higher_addr_match & (PADDR[5:2]==4'h8);

// PRDATA
always @(*) begin
    PRDATA=32'h0;
    if (r_en & higher_addr_match) begin
        case(PADDR[5:2])
            4'h0: begin
                PRDATA = {29'h0, MD_DRV, MD_PHY_WIDTH, soft_reset};
            end
            4'h1: begin
                PRDATA = {20'h0, MD_DEV, MD_PHY, MD_OP};
            end
            4'h2: begin
                PRDATA = {16'h0, MD_RXD};
            end
            4'h3: begin
                PRDATA = {16'h0, MD_ADR};
            end
            4'h4: begin
                PRDATA = {16'h0, MD_TXD};
            end
            4'h5: begin
                PRDATA = {17'h0, MD_DEVADD, MD_PHYSEL, MD_PHYSW};
            end
            4'h6: begin
                PRDATA = {24'h0, MD_PHYN, MD_PHYM, MD_DEVN, MD_DEVM, MD_RDF, MD_INCF, MD_ADRF, MD_WRF};
            end
            4'h7: begin
                PRDATA = {24'h0, MD_PHYNI, MD_PHYMI, MD_DEVNI, MD_DEVMI, MD_RDFI, MD_INCFI, MD_ADRI, MD_WRFI};
            end
            4'h8: begin
                PRDATA = {27'h0, PRTADR};
            end
        endcase
    end
    else begin
        PRDATA = 32'h0;
    end
end

// MDCON
always @(posedge PCLK or negedge PRESETn) begin
    if (~PRESETn) begin
        MD_DRV <= 1'b0;
        MD_PHY_WIDTH <= 1'b0;
    end
    else if (soft_reset) begin
        MD_DRV <= 1'b0;
        MD_PHY_WIDTH <= 1'b0;
    end
    else if (w_en & MDCON_addr_match) begin
        MD_DRV <= PWDATA[2];
        MD_PHY_WIDTH <= PWDATA[1];
    end
end

always @(posedge PCLK or negedge PRESETn) begin
    if (~PRESETn) begin
        soft_reset <= 1'b0;
    end
    else if (soft_reset) begin
        soft_reset <= 1'b0;
    end
    else if (w_en & MDCON_addr_match) begin
        soft_reset <= PWDATA[0];
    end
end

// MDFRM
always @(posedge PCLK or negedge PRESETn) begin
    if (~PRESETn) begin
        MD_OP <= 2'h0;;
    end
    else if (soft_reset) begin
        MD_OP <= 2'h0;
    end
    else if (opcode_ready & register_stage) begin
        MD_OP <= shift_reg_window[1:0];
    end
end

assign op_is_addr = (MD_OP==2'b00);
assign op_is_write = (MD_OP==2'b01);
assign op_is_read = (MD_OP==2'b11);
assign op_is_incr = (MD_OP==2'b10);
assign is_write = op_is_addr & op_is_write;

always @(posedge PCLK or negedge PRESETn) begin
    if (~PRESETn) begin
        MD_PHY <= 5'h0;
    end
    else if (soft_reset) begin
        MD_PHY <= 5'h0;
    end
    else if (phyadr_ready & register_stage) begin
        MD_PHY <= shift_reg_window[4:0];
    end
end

always @(posedge PCLK or negedge PRESETn) begin
    if (~PRESETn) begin
        MD_DEV <= 5'h0;
    end
    else if (soft_reset) begin
        MD_DEV <= 5'h0;
    end
    else if (devadr_ready & register_stage) begin
        MD_DEV <= shift_reg_window[4:0];
    end
end

// MDRXD
always @(posedge PCLK or negedge PRESETn) begin
    if (~PRESETn) begin
        MD_RXD <= 16'h0;
    end
    else if (soft_reset) begin
        MD_RXD <= 16'h0;
    end
    else if (data_ready & register_stage & op_is_write) begin
        MD_RXD <= shift_reg_window[15:0];
    end
end

// MDADR
always @(posedge PCLK or negedge PRESETn) begin
    if (~PRESETn) begin
        MD_ADR <= 16'h0;
    end
    else if (soft_reset) begin
        MD_ADR <= 16'h0;
    end
    else if (data_ready & register_stage & op_is_addr) begin
        MD_ADR <= shift_reg_window[15:0];
    end
end

// MDTXD
always @(posedge PCLK or negedge PRESETn) begin
    if (~PRESETn) begin
        MD_TXD <= 16'h0;
    end
    else if (soft_reset) begin
        MD_TXD <= 16'h0;
    end
    else if (w_en & MDTXD_addr_match) begin
        MD_TXD <= PWDATA[15:0];
    end
end
assign mdio_txd[15:0] = MD_TXD[15:0];

// MDPHY
always @(posedge PCLK or negedge PRESETn) begin
    if (~PRESETn) begin
        MD_DEVADD <= 5'h1;
        MD_PHYSEL <= 5'h0;
        MD_PHYSW <= 5'h0;
    end
    else if (soft_reset) begin
        MD_DEVADD <= 5'h1;
        MD_PHYSEL <= 5'h0;
        MD_PHYSW <= 5'h0;
    end
    else if (w_en & MDPHY_addr_match) begin
        MD_DEVADD <= PWDATA[14:10];
        MD_PHYSEL <= PWDATA[9:5];
        MD_PHYSW <= PWDATA[4:0];
    end
end

assign MD_PHYADD = (PRTADR & ~MD_PHYSEL) | (MD_PHYSW & MD_PHYSEL);

// MDSTA
always @(posedge PCLK or negedge PRESETn) begin
    if (~PRESETn) begin
        sta_rd <= 1'b0;
    end
    else if (soft_reset) begin
        sta_rd <= 1'b0;
    end
    else begin
        sta_rd <= r_en & MDSTA_addr_match;
    end
end

assign sta_rd_clr = ~(r_en & MDSTA_addr_match) & sta_rd;
assign devadr_match = (MD_DEVADD == MD_DEV);
assign phyadr_match = (MD_PHYADD == MD_PHY);
assign bothadr_match = devadr_match & phyadr_match;

always @(posedge PCLK or negedge PRESETn) begin
    if (~PRESETn) begin
        devadr_compare_stage <= 1'b0;
    end
    else if (soft_reset) begin
        devadr_compare_stage <= 1'b0;
    end
    else begin
        devadr_compare_stage <= devadr_ready & register_stage;
    end
end

always @(posedge PCLK or negedge PRESETn) begin
    if (~PRESETn) begin
        MD_DEVM <= 1'b0;
        MD_DEVN <= 1'b0;
    end
    else if (soft_reset | sta_rd_clr) begin
        MD_DEVM <= 1'b0;
        MD_DEVN <= 1'b0;
    end
    else if (devadr_compare_stage) begin
        MD_DEVM <= devadr_match;
        MD_DEVN <= ~devadr_match;
    end
end

always @(posedge PCLK or negedge PRESETn) begin
    if (~PRESETn) begin
        phyadr_compare_stage <= 1'b0;
    end
    else if (soft_reset) begin
        phyadr_compare_stage <= 1'b0;
    end
    else begin
        phyadr_compare_stage <= phyadr_ready & register_stage;
    end
end

always @(posedge PCLK or negedge PRESETn) begin
    if (~PRESETn) begin
        MD_PHYM <= 1'b0;
        MD_PHYN <= 1'b0;
    end
    else if (soft_reset | sta_rd_clr) begin
        MD_PHYM <= 1'b0;
        MD_PHYN <= 1'b0;
    end
    else if (phyadr_compare_stage) begin
        MD_PHYM <= phyadr_match;
        MD_PHYN <= ~phyadr_match;
    end
end

always @(posedge PCLK or negedge PRESETn) begin
    if (~PRESETn) begin
        MD_WRF <= 1'b0;
        MD_ADRF <= 1'b0;
        MD_INCF <= 1'b0;
        MD_RDF <= 1'b0;
    end
    else if (soft_reset | sta_rd_clr) begin
        MD_WRF <= 1'b0;
        MD_ADRF <= 1'b0;
        MD_INCF <= 1'b0;
        MD_RDF <= 1'b0;
    end
    else if (data_ready & bothadr_match) begin
        MD_WRF <= op_is_write;
        MD_ADRF <= op_is_addr;
        MD_INCF <= op_is_incr;
        MD_RDF <= op_is_read;
    end
end

//MDIEN
always @(posedge PCLK or negedge PRESETn) begin
    if (~PRESETn) begin
        MD_WRFI <= 1'b0;
        MD_ADRI <= 1'b0;
        MD_INCFI <= 1'b0;
        MD_RDFI <= 1'b0;
        MD_DEVMI <= 1'b0;
        MD_DEVNI <= 1'b0;
        MD_PHYMI <= 1'b0;
        MD_PHYNI <= 1'b0;
    end
    else if (soft_reset) begin
        MD_WRFI <= 1'b0;
        MD_ADRI <= 1'b0;
        MD_INCFI <= 1'b0;
        MD_RDFI <= 1'b0;
        MD_DEVMI <= 1'b0;
        MD_DEVNI <= 1'b0;
        MD_PHYMI <= 1'b0;
        MD_PHYNI <= 1'b0;
    end
    else if (w_en & MDIEN_addr_match) begin
        MD_WRFI <= PWDATA[0];
        MD_ADRI <= PWDATA[1];
        MD_INCFI <= PWDATA[2];
        MD_RDFI <= PWDATA[3];
        MD_DEVMI <= PWDATA[4];
        MD_DEVNI <= PWDATA[5];
        MD_PHYMI <= PWDATA[6];
        MD_PHYNI <= PWDATA[7];
    end
end

//irq
assign irq = (MD_WRFI & MD_WRF) | (MD_ADRI & MD_ADRF) |
             (MD_INCFI & MD_INCF) | (MD_RDFI & MD_RDF) |
             (MD_DEVMI & MD_DEVM) | (MD_DEVNI & MD_DEVN) |
             (MD_PHYMI & MD_PHYM) | (MD_PHYNI & MD_PHYN);

endmodule
