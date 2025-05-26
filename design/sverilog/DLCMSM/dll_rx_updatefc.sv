module dll_rx_updatefc (
    input  logic         clk,
    input  logic         rst_n,

    input  logic [1:0]   dlc_state_i,

    input  logic [135:0] dllp_i,
    input  logic         dllp_valid_i,

    // demux에서 받은 DLLP 타입 판별 결과
    input  logic         is_updatefc_i,

    output logic [11:0]  hdr_credit_o,
    output logic [11:0]  data_credit_o,
    output logic         update_valid_o
);

    localparam DLC_DL_ACTIVE = 2'b11;
    logic is_active;
    assign is_active = (dlc_state_i == DLC_DL_ACTIVE);

    wire [63:0] dllp_payload = dllp_i[63:0];

    wire [5:0] hdr_fc     = dllp_payload[55:50];
    wire [5:0] data_fc_hi = dllp_payload[47:42];
    wire [5:0] data_fc_lo = dllp_payload[39:34];
    wire [11:0] data_fc   = {data_fc_hi, data_fc_lo};

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            update_valid_o <= 1'b0;
        end
        else if (is_active && dllp_valid_i && is_updatefc_i) begin
            hdr_credit_o   <= {6'd0, hdr_fc};  // 12bit 정렬
            data_credit_o  <= data_fc;
            update_valid_o <= 1'b1;
        end
        else begin
            update_valid_o <= 1'b0;
        end
    end

endmodule
