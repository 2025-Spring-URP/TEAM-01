//============================================================
// FC_TX_Controller_Top : 송신측 Flow Control Top
//============================================================
// initFC, updateFC DLLP를 통해 수신 측 credit 정보를 업데이트하고,
// 송신 요청이 들어왔을 때 송신 측 credit 정보를 확인하여 송신을 허가하는 모듈
//============================================================
module FC_TX_Controller_Top (
    input  logic         clk,
    input  logic         rst_n,

    // DLLP를 통해 받은 credit 정보 (InitFC/UpdateFC)
    // DLLP의 0바이트 7,6비트가 01이면 InitFC1, 11이면 InitFC2, 10이면 UpdateFC
    // 0바이트 5,4비트가 00이면 MWr, 01이면 MRd, 10이면 Cpl
    input  logic [7:0]   hdr_credit_i,
    input  logic [11:0]  data_credit_i,
    input  logic         is_initFC_i,
    input  logic         is_updateFC_i,
    input  logic [1:0]   type_credit_i,     // 2'b00: MWr, 2'b01: MRd, 2'b10: Cpl

    // TLP buffer에서 송신 요청이 들어올 때 buffer로부터 받는 정보
    input  logic         send_tlp_req_i,    // 송신 요청 신호
    input  logic [1:0]   send_tlp_type_i,   // 2'b00: MWr, 2'b01: MRd, 2'b10: Cpl
    input  logic [7:0]   send_tlp_size_i,   // Payload 크기 (DW 단위)

    // Gating 결과 출력
    output logic         send_tlp_grant_o
);

    logic [7:0] cl_hdr, cc_hdr;
    logic [11:0] cl_data, cc_data;
    logic       gating_pass;
    logic [7:0] required_hdr_credit;
    logic [7:0] required_data_credit;

    // 1. Credit Limit 모듈
    fc_tx_credit_limit u_fc_tx_credit_limit (
        .clk                    (clk),
        .rst_n                  (rst_n),
        .hdr_credit_i           (hdr_credit_i),
        .data_credit_i          (data_credit_i),
        .is_initFC_i            (is_initFC_i),
        .is_updateFC_i          (is_updateFC_i),
        .type_credit_i          (type_credit_i),
        .send_tlp_type_i        (send_tlp_type_i),
        .cl_hdr_o               (cl_hdr),
        .cl_data_o              (cl_data)
    );

    // 2. Credit Counter 모듈
    fc_tx_credit_counter u_fc_tx_credit_counter (
        .clk                    (clk),
        .rst_n                  (rst_n),
        .is_initFC_i            (is_initFC_i),
        .send_tlp_req_i         (send_tlp_req_i),
        .send_tlp_type_i        (send_tlp_type_i),
        .gating_pass_i          (gating_pass),
        .required_hdr_credit_i  (required_hdr_credit),
        .required_data_credit_i (required_data_credit),
        .cc_hdr_o               (cc_hdr),
        .cc_data_o              (cc_data),
        .send_tlp_grant_o       (send_tlp_grant_o)
    );

    // 3. Gating Logic 모듈
    fc_tx_gating_logic u_fc_tx_gating_logic (
        .cl_hdr_i               (cl_hdr),
        .cl_data_i              (cl_data),
        .cc_hdr_i               (cc_hdr),
        .cc_data_i              (cc_data),
        .send_tlp_type_i        (send_tlp_type_i),
        .send_tlp_size_i        (send_tlp_size_i),
        .required_hdr_credit_o  (required_hdr_credit),
        .required_data_credit_o (required_data_credit),
        .gating_pass_o          (gating_pass)
    );
endmodule