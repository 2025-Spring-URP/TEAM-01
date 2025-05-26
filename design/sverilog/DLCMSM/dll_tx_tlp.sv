module dll_tx_tlp (
    input  logic         clk,
    input  logic         rst_n,

    // DLCMSM 상태
    input  logic [1:0]   dlc_state_i,

    // Transaction Layer 입력
    input  logic [127:0] tlp_i,
    input  logic         tlp_valid_i,

    // PHY 출력
    output logic [135:0] dllp_o,
    output logic         dllp_valid_o
);

    localparam DLC_DL_ACTIVE = 2'b11;

    logic is_active;
    assign is_active = (dlc_state_i == DLC_DL_ACTIVE);

    logic [135:0] dllp_data;

    always_comb begin
        dllp_data       = 136'd0;
        dllp_valid_o    = 1'b0;

        if (is_active && tlp_valid_i) begin
            dllp_data[135:8] = tlp_i;         // 128비트 TLP
            dllp_data[7:0]   = 8'h00;         // CRC (dummy)
            dllp_valid_o     = 1'b1;
        end
    end

    assign dllp_o = dllp_data;

endmodule
