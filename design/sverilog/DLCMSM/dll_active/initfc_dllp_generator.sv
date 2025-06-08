module initfc_dllp_generator (
    input  logic         clk,
    input  logic         rst_n,

    input  logic [1:0]   dlc_state_i,   
    input  logic [1:0]   init_type_i,    // 00: MWr, 01: MRd, 10: Cpl     .. allocator 모듈의 type_credit_i 입력과 동일                                         
    input  logic [7:0]   hdr_credit_i,
    input  logic [11:0]  data_credit_i,   

    output logic [47:0]  dll_dllp_o,
    output logic         dll_dllp_valid_o,

    output logic         is_initfc1_o,
    output logic         is_initfc2_o
);


    localparam P = 2'b00;
    localparam NP = 2'b01;
    localparam CPL = 2'b10;

    localparam INITFC1_P    = 4'b0100;
    localparam INITFC1_NP   = 4'b0101;
    localparam INITFC1_CPL  = 4'b0110;
    localparam INITFC2_P    = 4'b1100;
    localparam INITFC2_NP   = 4'b1101;
    localparam INITFC2_CPL  = 4'b1110;


    // state 정의
    localparam IDLE =       2'b00, 
               GENE_INIT1 = 2'b01, 
               GENE_INIT2 = 2'b10; 
    localparam DLC_DL_INIT1 = 2'b01, 
               DLC_DL_INIT2 = 2'b10;

    // 내부 레지스터 정의
    logic [1:0]  state, state_n;           
    logic [3:0]  dllp_type, dllp_type_n;
    logic [7:0]  hdr_credit, hdr_credit_n;
    logic [11:0] data_credit, data_credit_n;

    logic [47:0] dllp, dllp_n;
    logic        dllp_valid, dllp_valid_n;
    logic        is_initfc1, is_initfc1_n;
    logic        is_initfc2, is_initfc2_n;

    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            dllp <= 48'd0;
            dllp_valid <= 0;
            dllp_type <= 0;
            hdr_credit <= 0;
            data_credit <= 0;
            is_initfc1 <= 0;
            is_initfc2 <= 0;
        end 
        else begin
            state <= state_n;
            dllp <= dllp_n;
            dllp_valid <= dllp_valid_n;
            dllp_type <= dllp_type_n;
            hdr_credit <= hdr_credit_n;
            data_credit <= data_credit_n;
            is_initfc1 <= is_initfc1_n;
            is_initfc2 <= is_initfc2_n;
        end
    end


    always_comb begin
        // 기본값 유지
        state_n = state;
        dllp_n = dllp;
        dllp_valid_n = 1'b0;
        dllp_type_n = dllp_type;
        hdr_credit_n = hdr_credit;
        data_credit_n = data_credit;
        is_initfc1_n = 1'b0;
        is_initfc2_n = 1'b0;
        
        case (state)
            IDLE: begin
                if (dlc_state_i == DLC_DL_INIT1 || dlc_state_i == DLC_DL_INIT2) begin
                    // 입력 credit을 내부 레지스터에 저장
                    hdr_credit_n = hdr_credit_i;
                    data_credit_n = data_credit_i;

                    // DLLP 타입 설정 (P, NP, CPL 구분)
                    case ({dlc_state_i, init_type_i})
                        {DLC_DL_INIT1, P}:   dllp_type_n = INITFC1_P;
                        {DLC_DL_INIT1, NP}:  dllp_type_n = INITFC1_NP;
                        {DLC_DL_INIT1, CPL}: dllp_type_n = INITFC1_CPL;
                        {DLC_DL_INIT2, P}:   dllp_type_n = INITFC2_P;
                        {DLC_DL_INIT2, NP}:  dllp_type_n = INITFC2_NP;
                        {DLC_DL_INIT2, CPL}: dllp_type_n = INITFC2_CPL;
                        default:             dllp_type_n = 4'b0000; // 예외
                    endcase

                    if (dlc_state_i == DLC_DL_INIT1) begin
                        state_n = GENE_INIT1;
                        $display(" state_n = GENE_INIT1");
                    end
                    else if (dlc_state_i == DLC_DL_INIT2) begin
                        state_n = GENE_INIT2; 
                        $display(" state_n = GENE_INIT2"); 
                    end  
                end
            end
            GENE_INIT1: begin
                //BYTE 0
                dllp_n[7:4]   = dllp_type;
                dllp_n[3]     = 1'b0;
                dllp_n[2:0]   = 3'b000; 

                //BYTE 1
                dllp_n[15:14] = 2'b00;
                dllp_n[13:8]  = hdr_credit_n[7:2];

                //BYTE 2
                dllp_n[23:22] = hdr_credit_n[1:0];
                dllp_n[21:20] = 2'b00;
                dllp_n[19:16] = data_credit_n[11:8];

                //BYTE 3
                dllp_n[31:24] = data_credit_n[7:0];

                //BYTE 5,6
                //dllp_n[47:32] = 16'hFFFF; 

                dllp_valid_n = 1'b1;
                is_initfc1_n = 1'b1;
                state_n = IDLE;
            end
            GENE_INIT2: begin
                //BYTE 0
                dllp_n[7:4]   = dllp_type;
                dllp_n[3]     = 1'b0;
                dllp_n[2:0]   = 3'b000; 

                //BYTE 1
                dllp_n[15:14] = 2'b00;
                dllp_n[13:8]  = hdr_credit_n[7:2];

                //BYTE 2
                dllp_n[23:22] = hdr_credit_n[1:0];
                dllp_n[21:20] = 2'b00;
                dllp_n[19:16] = data_credit_n[11:8];

                //BYTE 3
                dllp_n[31:24] = data_credit_n[7:0];

                //BYTE 5,6
                //dllp_n[47:32] = 16'hFFFF;

                dllp_valid_n = 1'b1;
                is_initfc2_n = 1'b1;
                state_n = IDLE;
            end
        endcase
    end


    // CRC16 calculation------------------------------------
    wire [15:0] crc16_out;
    dllp_crc16_generator crc16 #(parameter crc16_POLY = 16'h100B)(
        .dllp_data(dllp_n[31:0]),
        .crc16_out(crc16_out)
    )
    assign dllp_n[47:32] = crc16_out[15:0];
    // -----------------------------------------------------

    assign dll_dllp_o = dllp;
    assign dll_dllp_valid_o = dllp_valid;
    assign is_initfc1_o = is_initfc1;
    assign is_initfc2_o = is_initfc2;

endmodule
