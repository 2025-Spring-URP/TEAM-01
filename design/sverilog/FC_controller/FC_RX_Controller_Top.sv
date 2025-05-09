//============================================================
// FC_RX_Controller_Top : 수신측 Flow Control Top (인스턴스화 전용 버전)
//============================================================
module FC_RX_Controller_Top (
    input  logic         clk,
    input  logic         rst_n,

    // 외부 버퍼로부터 받은 credit 정보 (InitFC/UpdateFC)
    input  logic [7:0]   buffer_hdr_credit_i,  // 수신 측 버퍼가 가지고 있던 저장 공간
    input  logic [11:0]  buffer_data_credit_i, // 수신 측 버퍼가 가지고 있던 저장 공간
    input  logic [7:0]   buffer_hdr_rsv_i,     // 수신 측 버퍼가 처리한 저장 공간
    input  logic [11:0]  buffer_data_rsv_i,   // 수신 측 버퍼가 처리한 저장 공간
    input  logic         is_initFC_i,
    input  logic         is_updateFC_i,
    input  logic [1:0]   type_credit_i,     // 2'b00: MWr, 2'b01: MRd, 2'b10: Cpl

    // 송신 측으로 전달하는 credit
    output  logic [7:0]   hdr_credit_o,
    output  logic [11:0]  data_credit_o,
    output  logic         initfc_send_o,
    output  logic         updatefc_send_o,
    output  logic [1:0]   type_send_o       // 2'b00: MWr, 2'b01: MRd, 2'b10: Cpl
);

    fc_rx_credit_allocator u_fc_rx_credit_allocator (
        .clk                   (clk),
        .rst_n                 (rst_n),

        .buffer_hdr_credit_i    (buffer_hdr_credit_i),
        .buffer_data_credit_i   (buffer_data_credit_i),
        .buffer_hdr_rsv_i       (buffer_hdr_rsv_i),
        .buffer_data_rsv_i      (buffer_data_rsv_i),
        .is_initFC_i            (is_initFC_i),
        .is_updateFC_i          (is_updateFC_i),
        .type_credit_i          (type_credit_i),

        .hdr_credit_o           (hdr_credit_o),
        .data_credit_o          (data_credit_o),
        .initfc_send_o          (initfc_send_o),
        .updatefc_send_o        (updatefc_send_o),
        .type_send_o            (type_send_o)
    );
endmodule