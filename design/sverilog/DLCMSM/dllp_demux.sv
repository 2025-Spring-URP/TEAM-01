module dllp_demux (
    input  logic [135:0] dllp_i,
    input  logic         dllp_valid_i,

    output logic         is_tlp_o,
    output logic         is_updatefc_o
);

    logic [3:0] dllp_type;

    // DLLP는 하위 64비트 기준으로 판단
    assign dllp_type = dllp_i[63:60];

    always_comb begin
        is_updatefc_o = 1'b0;
        is_tlp_o      = 1'b0;

        if (dllp_valid_i) begin
            // UpdateFC: Type == 4
            if (dllp_type == 4'h4)
                is_updatefc_o = 1'b1;
            else
                is_tlp_o = 1'b1; // DLLP가 아니면 TLP로 처리
        end
    end

endmodule
