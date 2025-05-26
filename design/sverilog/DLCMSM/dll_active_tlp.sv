module dll_active_layer (
    input  logic         clk,
    input  logic         rst_n,

    // DLCMSM 상태 (외부에서 입력받음)
    input  logic [1:0]   dlc_state_i,

    // Transaction Layer → TX
    input  logic [127:0] tlp_i,
    input  logic         tlp_valid_i,

    // RX → Transaction Layer
    output logic [127:0] tlp_o,
    output logic         tlp_valid_o,

    // Credit 관리
    input  logic [11:0]  hdr_credit_i,
    input  logic [11:0]  data_credit_i,
    output logic [11:0]  hdr_credit_o,
    output logic [11:0]  data_credit_o,
    output logic         update_valid_o,

    // PHY 인터페이스
    input  logic [135:0] phy_rx_data_i,
    input  logic         phy_rx_valid_i,
    output logic [135:0] phy_tx_data_o,
    output logic         phy_tx_valid_o
);

    // TX DLLP
    logic [135:0] tlp_dllp, updatefc_dllp;
    logic         tlp_valid, updatefc_valid;

    // RX demux
    logic is_tlp, is_updatefc;

    // TX TLP
    dll_tx_tlp u_tx_tlp (
        .clk(clk),
        .rst_n(rst_n),
        .dlc_state_i(dlc_state_i),
        .tlp_i(tlp_i),
        .tlp_valid_i(tlp_valid_i),
        .dllp_o(tlp_dllp),
        .dllp_valid_o(tlp_valid)
    );

    // TX UpdateFC
    dll_tx_updatefc u_tx_updatefc (
        .clk(clk),
        .rst_n(rst_n),
        .dlc_state_i(dlc_state_i),
        .hdr_credit_i(hdr_credit_i),
        .data_credit_i(data_credit_i),
        .dllp_o(updatefc_dllp),
        .dllp_valid_o(updatefc_valid)
    );

    // MUX
    dllp_mux u_dllp_mux (
        .tlp_dllp_i(tlp_dllp),
        .tlp_valid_i(tlp_valid),
        .updatefc_dllp_i(updatefc_dllp),
        .updatefc_valid_i(updatefc_valid),
        .dllp_o(phy_tx_data_o),
        .dllp_valid_o(phy_tx_valid_o)
    );

    // RX demux
    dllp_demux u_demux (
        .dllp_i(phy_rx_data_i),
        .dllp_valid_i(phy_rx_valid_i),
        .is_tlp_o(is_tlp),
        .is_updatefc_o(is_updatefc)
    );

    // RX TLP
    dll_rx_tlp u_rx_tlp (
        .clk(clk),
        .rst_n(rst_n),
        .dlc_state_i(dlc_state_i),
        .dllp_i(phy_rx_data_i),
        .dllp_valid_i(phy_rx_valid_i),
        .is_tlp_i(is_tlp),
        .tlp_o(tlp_o),
        .tlp_valid_o(tlp_valid_o)
    );

    // RX UpdateFC
    dll_rx_updatefc u_rx_fc (
        .clk(clk),
        .rst_n(rst_n),
        .dlc_state_i(dlc_state_i),
        .dllp_i(phy_rx_data_i),
        .dllp_valid_i(phy_rx_valid_i),
        .is_updatefc_i(is_updatefc),
        .hdr_credit_o(hdr_credit_o),
        .data_credit_o(data_credit_o),
        .update_valid_o(update_valid_o)
    );

endmodule
