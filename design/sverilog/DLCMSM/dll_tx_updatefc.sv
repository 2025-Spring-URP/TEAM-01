module dll_tx_updatefc #(
    parameter VC_ID = 0
)(
    input  logic         clk,
    input  logic         rst_n,

    // DLCMSM 상태
    input  logic [1:0]   dlc_state_i,

    // 로컬 credit 상태
    input  logic [11:0]  hdr_credit_i,
    input  logic [11:0]  data_credit_i,
    input  logic         is_update_i,

    // PHY 출력
    output logic [135:0] dllp_o,
    output logic         dllp_valid_o
);

    localparam DLC_DL_ACTIVE = 2'b11;

    logic is_active;
    logic [135:0] pipe_txdata;
    logic pipe_txvalid;
    logic [47:0] updatefc_payload;

    assign is_active = (dlc_state_i == DLC_DL_ACTIVE);

    always_comb begin
        updatefc_payload[47:40] = {4'h4, 1'b0, VC_ID[2:0]};
        updatefc_payload[39:32] = {2'b00, hdr_credit_i[5:0]};
        updatefc_payload[31:24] = {2'b00, data_credit_i[11:6]};
        updatefc_payload[23:16] = data_credit_i[5:0];
        updatefc_payload[15:0]  = 16'h0000;

        pipe_txdata     = 136'd0;
        pipe_txvalid    = 1'b0;

        if (is_active && is_update_i) begin
            pipe_txdata = {updatefc_payload, 88'd0};
            pipe_txvalid = 1'b0;
        end
    end

    assign pipe_txdata_o = pipe_txdata;
    assign pipe_txvalid_o = pipe_txvalid;

endmodule
