module fc_rx_credit_allocator (
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

    localparam MWr = 2'b00, // P (Posted)
               MRd = 2'b01, // NP (Non-posted)
               Cpl = 2'b10; // Cpl (Completion)
    localparam IDLE = 2'b00,
               inFC = 2'b01,
               upFC = 2'b10;

    logic [1:0]   state, state_n;
    logic [7:0]   ca_ph, ca_ph_n;
    logic [7:0]   ca_nph, ca_nph_n;
    logic [7:0]   ca_cplh, ca_cplh_n;
    logic [11:0]  ca_pd, ca_pd_n;
    logic [11:0]  ca_cpld, ca_cpld_n;
    logic         initfc_send, initfc_send_n;
    logic         updatefc_send, updatefc_send_n;

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            state <= IDLE;
            ca_ph <= 8'h00;
            ca_nph <= 8'h00;
            ca_cplh <= 8'h00;
            ca_pd <= 12'h000;
            ca_cpld <= 12'h000;
            initfc_send <= 1'b0;
            updatefc_send <= 1'b0;
        end
        else begin
            state <= state_n;
            ca_ph <= ca_ph_n;
            ca_nph <= ca_nph_n;
            ca_cplh <= ca_cplh_n;
            ca_pd <= ca_pd_n;
            ca_cpld <= ca_cpld_n;
            initfc_send <= initfc_send_n;
            updatefc_send <= updatefc_send_n;
        end
        
        $display("%0t: ca_ph=%d, ca_nph=%d, ca_cplh=%d, ca_pd=%d, ca_cpld=%d", $time, ca_ph, ca_nph, ca_cplh, ca_pd, ca_cpld);
        $display("%0t: ca_ph_n=%d, ca_nph_n=%d, ca_cplh_n=%d, ca_pd_n=%d, ca_cpld_n=%d", $time, ca_ph_n, ca_nph_n, ca_cplh_n, ca_pd_n, ca_cpld_n);
        $display("%0t: buffer_hdr_credit_i=%d, buffer_data_credit_i=%d", $time, buffer_hdr_credit_i, buffer_data_credit_i);
        $display("%0t: buffer_hdr_rsv_i=%d, buffer_data_rsv_i=%d", $time, buffer_hdr_rsv_i, buffer_data_rsv_i);
        $display("%0t: is_initFC_i=%b, is_updateFC_i=%b, type_credit_i=%b", $time, is_initFC_i, is_updateFC_i, type_credit_i);
        $display("%0t: state=%b, state_n=%b", $time, state, state_n);
        $display("-------------------------------------------------------------");
    end

    always_comb begin
        state_n = state;
        ca_ph_n = ca_ph;
        ca_nph_n = ca_nph;
        ca_cplh_n = ca_cplh;
        ca_pd_n = ca_pd;
        ca_cpld_n = ca_cpld;
        initfc_send_n = initfc_send;
        updatefc_send_n = updatefc_send;

        case(state)
            IDLE: begin
                if (is_initFC_i) begin
                    state_n = inFC;
                end
                else if (is_updateFC_i) begin
                    state_n = upFC;
                end
                else begin
                    state_n = IDLE;
                end
            end
            inFC: begin
                case (type_credit_i)
                    MWr : begin
                        ca_ph_n = buffer_hdr_credit_i;
                        ca_pd_n = buffer_data_credit_i;
                    end
                    MRd : begin
                        ca_nph_n = buffer_hdr_credit_i;
                    end
                    Cpl : begin
                        ca_cplh_n = buffer_hdr_credit_i;
                        ca_cpld_n = buffer_data_credit_i;
                    end
                    default: begin
                        ca_ph_n = ca_ph;
                        ca_nph_n = ca_nph;
                        ca_cplh_n = ca_cplh;
                        ca_pd_n = ca_pd;
                        ca_cpld_n = ca_cpld;
                    end
                endcase
                initfc_send_n = 1'b1;
                updatefc_send_n = 1'b0;
                state_n = IDLE;
            end
            upFC: begin
                case (type_credit_i)
                    MWr : begin
                        ca_ph_n = ca_ph + buffer_hdr_rsv_i;
                        ca_pd_n = ca_pd + buffer_data_rsv_i;
                    end
                    MRd : begin
                        ca_nph_n = ca_nph + buffer_hdr_rsv_i;
                    end
                    Cpl : begin
                        ca_cplh_n = ca_cplh + buffer_hdr_rsv_i;
                        ca_cpld_n = ca_cpld + buffer_data_rsv_i;
                    end
                    default: begin
                        ca_ph_n = ca_ph;
                        ca_nph_n = ca_nph;
                        ca_cplh_n = ca_cplh;
                        ca_pd_n = ca_pd;
                        ca_cpld_n = ca_cpld;
                    end
                endcase
                initfc_send_n = 1'b0;
                updatefc_send_n = 1'b1;
                state_n = IDLE;
            end
            default: begin
                state_n = IDLE;
                ca_ph_n = 8'h00;
                ca_nph_n = 8'h00;
                ca_cplh_n = 8'h00;
                ca_pd_n = 12'h000;
                ca_cpld_n = 12'h000;
                initfc_send_n = 1'b0;
                updatefc_send_n = 1'b0;
            end
        endcase
    end

    assign hdr_credit_o  =  (type_credit_i == MWr) ? ca_ph   :
                            (type_credit_i == MRd) ? ca_nph  :
                            (type_credit_i == Cpl) ? ca_cplh : 8'd0;
    assign data_credit_o =  (type_credit_i == MWr) ? ca_pd   :
                            (type_credit_i == MRd) ? 12'd0   :
                            (type_credit_i == Cpl) ? ca_cpld : 12'd0;
    assign initfc_send_o = initfc_send;
    assign updatefc_send_o = updatefc_send;
    assign type_send_o = type_credit_i;
endmodule