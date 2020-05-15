// ==================================================================
//                (C) COPYRIGHT Belling Co., Lmt.
//                      ALL RIGHTS RESERVED
// ==================================================================
//  File name         :  MDIO_counter.v
//  Author            :  Cheng Cai
//  File Initiation   :  2020-2-25
// ==================================================================


module MDIO_counter 
# (
    parameter   CNT_WIDTH=4
)
(
    input   wire                        clk,
    input   wire                        rstn,
    input   wire                        soft_reset,
    input   wire                        enable,
    input   wire                        clr,  // only clear when enabled
    output  reg     [CNT_WIDTH-1:0]     cnt
);

always @(posedge clk or negedge rstn) begin
    if (~rstn) begin
        cnt <= 'b0;
    end
    else if (soft_reset) begin
        cnt <= 'b0;
    end
    else if (enable) begin
        if (clr) begin
            cnt <= 'b0;
        end
        else begin
            cnt <= cnt +1;
        end
    end
end

endmodule
