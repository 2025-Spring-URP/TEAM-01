module dllp_mux (
    // 입력: TLP DLLP
    input  logic [135:0] tlp_dllp_i,
    input  logic         tlp_valid_i,

    // 입력: UpdateFC DLLP
    input  logic [135:0] updatefc_dllp_i,
    input  logic         updatefc_valid_i,

    // PHY 출력
    output logic [135:0] dllp_o,
    output logic         dllp_valid_o
);

    always_comb begin
        if (updatefc_valid_i) begin
            dllp_o       = updatefc_dllp_i;
            dllp_valid_o = 1'b1;
        end else if (tlp_valid_i) begin
            dllp_o       = tlp_dllp_i;
            dllp_valid_o = 1'b1;
        end else begin
            dllp_o       = 136'd0;
            dllp_valid_o = 1'b0;
        end
    end

endmodule
