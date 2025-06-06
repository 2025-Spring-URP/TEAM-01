module dlcmsm (
    input  logic        clk,
    input  logic        rst_n,

    // LTSSM으로부터 받은 L0 진입 신호
    input  logic        enter_l0_i,

    // InitFC1 상태 확인
    input  logic        initfc_sent_i,
    input  logic        initfc_received_i,

    // InitFC2 상태 확인
    input  logic        initfc2_sent_i,
    input  logic        initfc2_received_i,

    // 현재 상태 출력
    output logic  state_o
);

    localparam DLC_INACTIVE   = 2'b00,
               DLC_DL_INIT1   = 2'b01,
               DLC_DL_INIT2   = 2'b10,
               DLC_DL_ACTIVE  = 2'b11;

    reg state, state_n;

    // 상태 전이
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= DLC_INACTIVE;
        else
            state <= state_n;
    end

    // 상태 결정
    always_comb begin
        state_n = state;

        case (state)
            DLC_INACTIVE:
                if (enter_l0_i) begin
                    state_n = DLC_DL_INIT1;
                end
                else begin
                    state_n = DLC_INACTIVE;
                end

            DLC_DL_INIT1:
                if (enter_l0_i != 1'b1) begin
                    state_n = DLC_INACTIVE;
                end
                else if (initfc_sent_i && initfc_received_i) begin
                    state_n = DLC_DL_INIT2;
                end
                else begin
                    state_n = DLC_DL_INIT1;
                end

            DLC_DL_INIT2:
                if (enter_l0_i != 1'b1) begin
                    state_n = DLC_INACTIVE;
                end
                else if (initfc2_sent_i && initfc2_received_i) begin
                    state_n = DLC_DL_ACTIVE;
                end
                else begin
                    state_n = DLC_DL_INIT2;
                end

            DLC_DL_ACTIVE:
                if (enter_l0_i != 1'b1) begin
                    state_n = DLC_INACTIVE;
                end
                else begin
                    state_n = DLC_DL_ACTIVE;
                end

            default:
                state_n = DLC_INACTIVE;
        endcase
    end

    assign state_o = state;

endmodule
