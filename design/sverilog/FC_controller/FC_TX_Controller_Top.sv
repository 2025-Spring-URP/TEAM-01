//============================================================
// FC_TX_Controller_Top : 송신측 Flow Control Top (인스턴스화 전용 버전)
//============================================================
module FC_TX_Controller_Top (
    input  logic         clk,
    input  logic         rst_n,

    // InitFC 입력
    input  logic [7:0]   initfc_hdr_credit_i,
    input  logic [11:0]   initfc_data_credit_i,
    input  logic         initfc_valid_i,

    // UpdateFC 입력
    input  logic [7:0]   updatefc_hdr_credit_i,
    input  logic [11:0]   updatefc_data_credit_i,
    input  logic         updatefc_valid_i,

    // 송신할 TLP 입력
    input  logic         send_tlp_req_i,
    input  logic [1:0]   send_tlp_type_i,   // 2'b00: MWr, 2'b01: MRd, 2'b10: Cpl
    input  logic [7:0]   send_tlp_size_i,   // Payload 크기 (DW 단위)
    input  logic [127:0] send_tlp_data_i,

    // Gating 결과 출력
    output logic         send_tlp_grant_o,

    // 실제 송신할 TLP
    output logic [127:0] tlp_out_o
);

    //============================================================
    // 내부 연결 신호 (wires)
    //============================================================
    logic [7:0] cl_hdr, cl_data;
    logic [7:0] cc_hdr, cc_data;
    logic       gating_pass;            // gating logic을 통과했는지 여부
    logic [7:0] required_hdr_credit;    // TLP 송신시 필요 Header Credit 소모량
    logic [7:0] required_data_credit;   // TLP 송신시 필요 Data Credit 소모량

    //============================================================
    // 서브모듈 인스턴스화
    //============================================================

    // 1. Credit Limit 모듈
    fc_tx_credit_limit u_fc_tx_credit_limit (
        .clk                 (clk),
        .rst_n               (rst_n),
        .initfc_hdr_credit_i  (initfc_hdr_credit_i),
        .initfc_data_credit_i (initfc_data_credit_i),
        .initfc_valid_i       (initfc_valid_i),
        .updatefc_hdr_credit_i(updatefc_hdr_credit_i),
        .updatefc_data_credit_i(updatefc_data_credit_i),
        .updatefc_valid_i     (updatefc_valid_i),
        .cl_hdr_o             (cl_hdr),
        .cl_data_o            (cl_data)
    );

    // 2. Credit Counter 모듈
    fc_tx_credit_counter u_fc_tx_credit_counter (
        .clk                 (clk),
        .rst_n               (rst_n),
        .send_tlp_req_i       (send_tlp_req_i),
        .gating_pass_i        (gating_pass),
        .required_hdr_credit_i(required_hdr_credit),
        .required_data_credit_i(required_data_credit),
        .cc_hdr_o             (cc_hdr),
        .cc_data_o            (cc_data)
    );

    // 3. Gating Logic 모듈
    fc_tx_gating_logic u_fc_tx_gating_logic (
        .cl_hdr_i             (cl_hdr),
        .cl_data_i            (cl_data),
        .cc_hdr_i             (cc_hdr),
        .cc_data_i            (cc_data),
        .send_tlp_type_i      (send_tlp_type_i),
        .send_tlp_size_i      (send_tlp_size_i),
        .required_hdr_credit_o(required_hdr_credit),
        .required_data_credit_o(required_data_credit),
        .gating_pass_o        (gating_pass)
    );

    // 4. Buffer 모듈
    fc_tx_buffer u_fc_tx_buffer (
        .clk                 (clk),
        .rst_n               (rst_n),
        .send_tlp_req_i       (send_tlp_req_i),
        .gating_pass_i        (gating_pass),
        .send_tlp_data_i      (send_tlp_data_i),
        .tlp_out_o            (tlp_out_o)
    );

    // 5. Link Packet Control 모듈
    fc_tx_link_packet_ctrl u_fc_tx_link_packet_ctrl (
        .initfc_valid_i       (initfc_valid_i),
        .updatefc_valid_i     (updatefc_valid_i)
        // 이 모듈은 InitFC/UpdateFC 수신 여부에 따라 신호 정리하는 용도
    );

    assign send_tlp_grant_o = send_tlp_req_i && gating_pass;

endmodule
