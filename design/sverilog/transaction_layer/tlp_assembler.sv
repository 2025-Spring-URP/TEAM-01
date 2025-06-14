`timescale 1ns/1ps

module tlp_assembler #(
    parameter PAYLOAD_WIDTH = PCIE_PKG::PIPE_DATA_WIDTH  // 예: 256 (즉 32B)
)(
    input  wire                      clk,
    input  wire                      rst_n,

    //--- AW FIFO 인터페이스 ---
    input  wire                      aw_fifo_empty,
    input  wire [127:0]              aw_fifo_data,
    output reg                       aw_fifo_rden,

    //--- AR FIFO 인터페이스 ---
    input  wire                      ar_fifo_empty,
    input  wire [127:0]              ar_fifo_data,
    output reg                       ar_fifo_rden,

    //--- Payload FIFO 인터페이스 ---
    input  wire                      pw_fifo_empty,
    input  wire [PAYLOAD_WIDTH-1:0]  pw_fifo_data,
    input  wire                      pw_fifo_last,
    output reg                       pw_fifo_rden,

    //--- 최종 TLP 출력 인터페이스 ---
    output reg                       tlp_out_valid,
    output reg [PAYLOAD_WIDTH-1:0]   tlp_out_data,
    output reg                       tlp_out_last
);

    // FSM 상태 정의
    typedef enum logic [1:0] {
        IDLE          = 2'b00,
        SEND_AW_HDR   = 2'b01,
        SEND_AW_PAY   = 2'b10,
        SEND_AR_HDR   = 2'b11
    } state_t;

    state_t    state, next_state;

  
    // 내부 레지스터: AW 헤더를 보낼 때, payload가 끝났는지 추적하기 위한 플래그
    reg        aw_header_pending;    // AW 헤더를 아직 보내지 않았으면 1
    reg        aw_payload_pending;   // AW 페이로드를 보내고 있는 중이면 1
    // aw_payload_pending이 1일 때, pw_fifo_last가 나오면 한 TLP가 끝난 것

    // FSM 
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state               <= IDLE;
            aw_header_pending   <= 1'b0;
            aw_payload_pending  <= 1'b0;
        end else begin
            state               <= next_state;

            // AW 헤더와 페이로드 플래그 초기화화
            if (state == IDLE) begin
                aw_header_pending  <= 1'b0;
                aw_payload_pending <= 1'b0;
            end else if (state == SEND_AW_HDR) begin
                aw_header_pending  <= 1'b1;   // 바로 헤더를 읽고 내보낼 준비
            end else if (state == SEND_AW_PAY) begin
                aw_payload_pending <= 1'b1;  // 페이로드 읽기 시작작
            end else if (state == SEND_AR_HDR) begin
                aw_header_pending  <= 1'b0;
                aw_payload_pending <= 1'b0;
            end
        end
    end

    // 다음 상태
    always_comb begin
        // default: 유지
        next_state = state;

        case (state)
            IDLE: begin
                // AW FIFO에 데이터(헤더)가 있고 Payload FIFO에도 최소 한 워드 이상 남아 있으면
                // AW TLP 처리 모드 진입
                if (!aw_fifo_empty && !pw_fifo_empty) begin
                    next_state = SEND_AW_HDR;
                end
                // AW가 없으면 AR 처리 시도
                else if (!ar_fifo_empty) begin
                    next_state = SEND_AR_HDR;
                end
                // 모두 비어있으면 IDLE 유지
            end
            SEND_AW_HDR: begin
                // 헤더가 한 싸이클 출력된 뒤 -> 즉시 페이로드 단계로
                next_state = SEND_AW_PAY;
            end
            SEND_AW_PAY: begin
                // 페이로드를 보내다가 마지막 pw_fifo_last가 나온 싸이클 -> AR 대기로 이동
                if (pw_fifo_last && !pw_fifo_empty) begin
                    next_state = SEND_AR_HDR;
                end
                // pw_fifo_empty라면 payload가 부족한 상태 -> IDLE(다시 대기)
                else if (pw_fifo_empty) begin
                    next_state = IDLE;
                end
                // 그 외: 계속 SEND_AW_PAY 유지
            end


            SEND_AR_HDR: begin
                // AR 헤더도 1싸이클만 보낸 뒤 -> 다시 IDLE
                next_state = IDLE;
            end

            default: next_state = IDLE;
        endcase
    end


    // 출력/제어 신호 생성
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // 모든 인터페이스 신호 초기화
            aw_fifo_rden    <= 1'b0;
            ar_fifo_rden    <= 1'b0;
            pw_fifo_rden    <= 1'b0;
            tlp_out_valid   <= 1'b0;
            tlp_out_data    <= {PAYLOAD_WIDTH{1'b0}};
            tlp_out_last    <= 1'b0;
        end else begin
            // 기본값으로 모두 0으로 놓고, 필요한 경우만 1로 셋
            aw_fifo_rden    <= 1'b0;
            ar_fifo_rden    <= 1'b0;
            pw_fifo_rden    <= 1'b0;
            tlp_out_valid   <= 1'b0;
            tlp_out_data    <= {PAYLOAD_WIDTH{1'b0}};
            tlp_out_last    <= 1'b0;

            case (state)
                IDLE: begin
                    // 아무것도 출력하지 않음
                end

                SEND_AW_HDR: begin
                    // AW FIFO에서 헤더 1싸이클 읽기
                    aw_fifo_rden  <= 1'b1;
                    // tlp_out_data: 헤더(128비트)를 상위 비트에 배치하고
                    //                하위 비트(256-128=128비트)는 모두 0으로 패딩
                    tlp_out_data  <= { aw_fifo_data, { (PAYLOAD_WIDTH-128){1'b0} } };
                    tlp_out_valid <= 1'b1;
                    // 헤더 워드는 "마지막 페이로드이 아님"이므로 tlp_out_last=0
                    tlp_out_last  <= 1'b0;
                end

                SEND_AW_PAY: begin
                    if (!pw_fifo_empty) begin
                        // Payload FIFO에서 매 싸이클 하나씩 읽기
                        pw_fifo_rden  <= 1'b1;
                        tlp_out_data  <= pw_fifo_data;
                        tlp_out_valid <= 1'b1;
                        // 마지막 pw_fifo_last 싸이클에만 last=1
                        if (pw_fifo_last) begin
                            tlp_out_last <= 1'b1;
                        end else begin
                            tlp_out_last <= 1'b0;
                        end
                    end
                end

                SEND_AR_HDR: begin
                    // AR FIFO에서 헤더 1싸이클 읽기
                    ar_fifo_rden  <= 1'b1;
                    // 마찬가지로 128비트 헤더를 상위 비트에 두고 나머지 0으로 채움
                    tlp_out_data  <= { ar_fifo_data, { (PAYLOAD_WIDTH-128){1'b0} } };
                    tlp_out_valid <= 1'b1;
                    // AR 헤더는 페이로드가 없으므로 바로 "마지막 워드"
                    tlp_out_last  <= 1'b1;
                end

                default: begin
                    // 그 외: 유지
                end
            endcase
        end
    end

endmodule
