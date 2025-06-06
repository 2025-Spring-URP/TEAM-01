module data_link_layer_active (
    input  logic          clk,
    input  logic          rst_n,

    // RX from PHY
    input  logic [1195:0] rx_data_i,
    input  logic          rx_valid_i,

    // TX to PHY
    output logic [1195:0] tx_data_o,
    output logic          tx_valid_o,

    // TLP input from Transaction Layer
    input  logic [1151:0] tlp_i,
    input  logic          tlp_valid_i,

    // UpdateFC request from Flow Control Unit
    input  logic [7:0]    hdr_credit_i,
    input  logic [11:0]   data_credit_i,
    input  logic [1:0]    update_type_i,
    input  logic          update_req_i,

    // UpdateFC info to Flow Control Unit
    output logic          is_updatefc_o,
    output logic [1:0]    fc_type_o,
    output logic [5:0]    hdr_credit_o,
    output logic [11:0]   data_credit_o,

    // TLP output to Transaction Layer
    output logic [1151:0] tlp_o,
    output logic          tlp_valid_o
);

    // 상태 고정: 항상 Active
    logic [1:0] dlc_state_i;
    assign dlc_state_i = 2'b11;

    // Internal wires
    logic [47:0]   dllp_rx;
    logic          dllp_rx_valid;
    logic [1195:0] tlp_rx;
    logic          tlp_rx_valid;

    logic [47:0]   dllp_tx;
    logic          dllp_tx_valid;
    logic [1195:0] dll_tlp_tx;
    logic          dll_tlp_tx_valid;

    // RX Demux
    dll_rx_packet_demux u_demux (
        .clk         (clk),
        .rst_n       (rst_n),
        .dlc_state_i (dlc_state_i),
        .rx_data_i   (rx_data_i),
        .rx_valid_i  (rx_valid_i),
        .dllp_o      (dllp_rx),
        .dllp_valid_o(dllp_rx_valid),
        .tlp_o       (tlp_rx),
        .tlp_valid_o (tlp_rx_valid)
    );

    // DLLP Checker
    dll_rx_dllp_checker u_dllp_checker (
        .clk           (clk),
        .rst_n         (rst_n),
        .dllp_i        (dllp_rx),
        .dllp_valid_i  (dllp_rx_valid),
        .is_updatefc_o (is_updatefc_o),
        .fc_type_o     (fc_type_o),
        .hdr_credit_o  (hdr_credit_o),
        .data_credit_o (data_credit_o)
    );

    // TLP Checker
    dll_rx_tlp_checker u_tlp_checker (
        .clk            (clk),
        .rst_n          (rst_n),
        .dll_tlp_i      (tlp_rx),
        .dll_tlp_valid_i(tlp_rx_valid),
        .tlp_o          (tlp_o),
        .tlp_valid_o    (tlp_valid_o)
    );

    // DLLP Generator
    dll_tx_dllp_generator u_dllp_gen (
        .clk              (clk),
        .rst_n            (rst_n),
        .dlc_state_i      (dlc_state_i),
        .hdr_credit_i     (hdr_credit_i),
        .data_credit_i    (data_credit_i),
        .update_type_i    (update_type_i),
        .update_req_i     (update_req_i),
        .dll_dllp_o       (dllp_tx),
        .dll_dllp_valid_o (dllp_tx_valid)
    );

    // TLP Generator
    dll_tx_tlp_generator u_tlp_gen (
        .clk              (clk),
        .rst_n            (rst_n),
        .dlc_state_i      (dlc_state_i),
        .tlp_i            (tlp_i),
        .tlp_valid_i      (tlp_valid_i),
        .dll_tlp_o        (dll_tlp_tx),
        .dll_tlp_valid_o  (dll_tlp_tx_valid)
    );

    // TX Arbiter
    dll_tx_arbiter u_tx_arbiter (
        .clk         (clk),
        .rst_n       (rst_n),
        .dllp_i      (dllp_tx),
        .dllp_valid_i(dllp_tx_valid),
        .tlp_i       (dll_tlp_tx),
        .tlp_valid_i (dll_tlp_tx_valid),
        .tx_data_o   (tx_data_o),
        .tx_valid_o  (tx_valid_o)
    );

endmodule
