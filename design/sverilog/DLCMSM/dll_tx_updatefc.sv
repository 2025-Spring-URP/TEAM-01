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

    // PHY 출력
    output logic [135:0] dllp_o,
    output logic         dllp_valid_o
);

    localparam DLC_DL_ACTIVE = 2'b11;
    logic is_active;
    assign is_active = (dlc_state_i == DLC_DL_ACTIVE);

    logic [47:0] updatefc_payload;

    always_comb begin
        updatefc_payload[47:40] = {4'h4, 1'b0, VC_ID[2:0]};
        updatefc_payload[39:32] = {2'b00, hdr_credit_i[5:0]};
        updatefc_payload[31:24] = {2'b00, data_credit_i[11:6]};
        updatefc_payload[23:16] = data_credit_i[5:0];
        updatefc_payload[15:0]  = 16'h0000;
    end

    always_comb begin
        if (is_active) begin
            dllp_valid_o = 1'b1;
            dllp_o       = {updatefc_payload, 88'd0};
        end
        else begin
            dllp_valid_o = 1'b0;
            dllp_o       = 136'd0;
        end
    end

endmodule
