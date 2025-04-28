//============================================================
// FC_Controller_Top : 송신/수신 통합 Flow Control Top 모듈
//============================================================
module FC_Controller_Top (
    input  logic         clk,
    input  logic         rst_n,

    // InitFC 입력 (송신/수신 공통)
    input  logic [7:0]   initfc_hdr_credit_i,
    input  logic [11:0]   initfc_data_credit_i,
    input  logic         initfc_valid_i,

    // UpdateFC 입력 (송신측)
    input  logic [7:0]   updatefc_hdr_credit_i,
    input  logic [11:0]   updatefc_data_credit_i,
    input  logic         updatefc_valid_i,

    // 송신할 TLP 입력
    input  logic         send_tlp_req_i,
    input  logic [1:0]   send_tlp_type_i,    // 2'b00: MWr, 2'b01: MRd, 2'b10: Cpl
    input  logic [7:0]   send_tlp_size_i,
    input  logic [127:0] send_tlp_data_i,

    // 수신된 TLP 입력
    input  logic         rcv_tlp_valid_i,
    input  logic [1:0]   rcv_tlp_type_i,
    input  logic [7:0]   rcv_tlp_size_i,

    // 수신한 TLP 처리 완료 신호
    input  logic         tlp_processed_i,

    // 송신용 Gating 결과 출력
    output logic         send_tlp_grant_o,

    // 실제 송신할 TLP
    output logic [127:0] tlp_out_o,

    // UpdateFC DLLP 송신 요청 (수신측 기준)
    output logic [7:0]   updatefc_hdr_credit_o,
    output logic [11:0]   updatefc_data_credit_o,
    output logic         updatefc_send_o
);

    //============================================================
    // 송신측 FC_TX_Controller_Top 인스턴스
    //============================================================
    FC_TX_Controller_Top u_fc_tx_controller_top (
        .clk                    (clk),
        .rst_n                  (rst_n),

        .initfc_hdr_credit_i     (initfc_hdr_credit_i),
        .initfc_data_credit_i    (initfc_data_credit_i),
        .initfc_valid_i          (initfc_valid_i),

        .updatefc_hdr_credit_i   (updatefc_hdr_credit_i),
        .updatefc_data_credit_i  (updatefc_data_credit_i),
        .updatefc_valid_i        (updatefc_valid_i),

        .send_tlp_req_i          (send_tlp_req_i),
        .send_tlp_type_i         (send_tlp_type_i),
        .send_tlp_size_i         (send_tlp_size_i),
        .send_tlp_data_i         (send_tlp_data_i),

        .send_tlp_grant_o        (send_tlp_grant_o),
        .tlp_out_o               (tlp_out_o)
    );

    //============================================================
    // 수신측 FC_RX_Controller_Top 인스턴스
    //============================================================
    FC_RX_Controller_Top u_fc_rx_controller_top (
        .clk                    (clk),
        .rst_n                  (rst_n),

        .initfc_hdr_credit_i     (initfc_hdr_credit_i),
        .initfc_data_credit_i    (initfc_data_credit_i),
        .initfc_valid_i          (initfc_valid_i),

        .updatefc_hdr_credit_o   (updatefc_hdr_credit_o),
        .updatefc_data_credit_o  (updatefc_data_credit_o),
        .updatefc_send_o         (updatefc_send_o),

        .rx_tlp_valid_i          (rcv_tlp_valid_i),
        .rx_tlp_type_i           (rcv_tlp_type_i),
        .rx_tlp_size_i           (rcv_tlp_size_i),

        .tlp_processed_i         (tlp_processed_i)
    );

endmodule
