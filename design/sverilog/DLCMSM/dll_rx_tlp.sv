module dll_rx_tlp (
    input  logic         clk,
    input  logic         rst_n,

    input  logic [1:0]   dlc_state_i,

    // PHY에서 받은 DLLP
    input  logic [135:0] dllp_i,
    input  logic         dllp_valid_i,

    // demux가 판별한 TLP 유효 여부
    input  logic         is_tlp_i,

    // Transaction Layer로 출력
    output logic [127:0] tlp_o,
    output logic         tlp_valid_o
);

    localparam DLC_DL_ACTIVE = 2'b11;
    logic is_active;
    assign is_active = (dlc_state_i == DLC_DL_ACTIVE);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tlp_o       <= 128'd0;
            tlp_valid_o <= 1'b0;
        end
        else if (is_active && dllp_valid_i && is_tlp_i) begin
            tlp_o       <= dllp_i[135:8];
            tlp_valid_o <= 1'b1;
        end
        else begin
            tlp_valid_o <= 1'b0;
        end
    end

endmodule
