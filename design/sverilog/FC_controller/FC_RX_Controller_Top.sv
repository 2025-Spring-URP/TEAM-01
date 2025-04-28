//============================================================
// FC_RX_Controller_Top : 수신측 Flow Control Top (인스턴스화 전용 버전)
//============================================================
module FC_RX_Controller_Top (
    input  logic         clk,
    input  logic         rst_n,

    // InitFC 입력 (초기 Credit 설정)
    input  logic [7:0]   initfc_hdr_credit_i,
    input  logic [11:0]   initfc_data_credit_i,
    input  logic         initfc_valid_i,

    // UpdateFC DLLP 송신을 위한 출력
    output logic [7:0]   updatefc_hdr_credit_o,
    output logic [11:0]   updatefc_data_credit_o,
    output logic         updatefc_send_o,

    // 수신된 TLP 입력
    input  logic         rcv_tlp_valid_i,
    input  logic [1:0]   rcv_tlp_type_i,    // 2'b00: MWr, 2'b01: MRd, 2'b10: Cpl
    input  logic [7:0]   rcv_tlp_size_i,    // Payload 크기 (DW 단위)

    // 수신한 TLP 처리 완료 신호
    input  logic         tlp_processed_i
);

    //============================================================
    // 내부 연결 신호 (wires)
    //============================================================
    logic [7:0] ca_hdr, ca_data;
    logic [7:0] free_hdr_credit;
    logic [7:0] free_data_credit;
    logic       updatefc_trigger;

    //============================================================
    // 서브모듈 인스턴스화
    //============================================================

    // 1. Receive Buffer 모듈
    fc_rx_buffer u_fc_rx_buffer (
        .clk                  (clk),
        .rst_n                (rst_n),
        .rx_tlp_valid_i       (rcv_tlp_valid_i),
        .rx_tlp_type_i        (rcv_tlp_type_i),
        .rx_tlp_size_i        (rcv_tlp_size_i),
        .tlp_processed_i      (tlp_processed_i),
        .free_hdr_credit_o    (free_hdr_credit),
        .free_data_credit_o   (free_data_credit)
    );

    // 2. Credit Allocator 모듈
    fc_rx_credit_allocator u_fc_rx_credit_allocator (
        .clk                  (clk),
        .rst_n                (rst_n),
        .initfc_hdr_credit_i   (initfc_hdr_credit_i),
        .initfc_data_credit_i  (initfc_data_credit_i),
        .initfc_valid_i        (initfc_valid_i),
        .free_hdr_credit_i     (free_hdr_credit),
        .free_data_credit_i    (free_data_credit),
        .ca_hdr_o              (ca_hdr),
        .ca_data_o             (ca_data),
        .updatefc_trigger_o    (updatefc_trigger)
    );

    // 3. Link Packet Control 모듈
    fc_rx_link_packet_ctrl u_fc_rx_link_packet_ctrl (
        .ca_hdr_i              (ca_hdr),
        .ca_data_i             (ca_data),
        .updatefc_trigger_i    (updatefc_trigger),
        .updatefc_hdr_credit_o (updatefc_hdr_credit_o),
        .updatefc_data_credit_o(updatefc_data_credit_o),
        .updatefc_send_o       (updatefc_send_o)
    );

endmodule
