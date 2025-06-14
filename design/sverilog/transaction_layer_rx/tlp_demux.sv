`timescale 1ns/1ps
import PCIE_PKG::*;


// File: tlp_demux.sv
module tlp_demux #(
  parameter int DATA_WIDTH = PCIE_PKG::PIPE_DATA_WIDTH  // 256비트 폭
)(
  input  wire                  clk,
  input  wire                  rst_n,
  input  wire                  tlp_in_valid,  // Link layer TLP 유효
  input  wire [DATA_WIDTH-1:0] tlp_in_data,   // TLP 데이터(헤더+페이로드)
  input  wire                  tlp_in_last,   // 마지막 beat인지

  // AR 요청 헤더 분기
  output reg                   ar_hdr_wren,
  output reg  [127:0]          ar_hdr_data,
  // AW 요청 헤더 분기
  output reg                   aw_hdr_wren,
  output reg  [127:0]          aw_hdr_data,
  // Write 페이로드 분기
  output reg                   wr_pay_wren,
  output reg  [DATA_WIDTH-1:0] wr_pay_data,
  output reg                   wr_pay_last,
  // Read-Completion 헤더 분기
  output reg                   rc_hdr_wren,
  output reg  [127:0]          rc_hdr_data,
  // Read-Completion 페이로드 분기
  output reg                   rc_pay_wren,
  output reg  [DATA_WIDTH-1:0] rc_pay_data,
  output reg                   rc_pay_last
);

  // 상태기계: 헤더 처리(IDLE) vs 페이로드 처리(PAY)
  typedef enum logic [1:0] {IDLE, PAY} state_t;
  state_t state, next_state;

  // TLP 포맷/타입 판별용
  logic [127:0] header_word = tlp_in_data[DATA_WIDTH-1 -:128];
  logic [2:0] fmt    = header_word[39 -:3];
  logic [4:0] tlp_t  = header_word[2  -:5];

  // 일시 보관 플래그
  logic is_wr_req, is_rd_req, is_rd_cpl;

  // 상태 전이
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) state <= IDLE;
    else        state <= next_state;
  end

  always_comb begin
    next_state = state;
    is_wr_req = (fmt==PCIE_PKG::FMT_MEM_WR && tlp_t==5'b00000);
    is_rd_req = (fmt==PCIE_PKG::FMT_MEM_RD && tlp_t==5'b00000);
    is_rd_cpl = (fmt==PCIE_PKG::FMT_CPL_WITH_DATA && tlp_t==PCIE_PKG::TLP_TYPE_CPL);
    case (state)
      IDLE: if (tlp_in_valid) next_state = is_wr_req ? PAY : IDLE;
      PAY:  if (tlp_in_valid && tlp_in_last) next_state = IDLE;
    endcase
  end

  // 출력 제어
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      ar_hdr_wren<=0; aw_hdr_wren<=0; wr_pay_wren<=0;
      rc_hdr_wren<=0; rc_pay_wren<=0;
    end else begin
      // 기본 클리어
      ar_hdr_wren<=0; aw_hdr_wren<=0; wr_pay_wren<=0;
      rc_hdr_wren<=0; rc_pay_wren<=0;

      if (state==IDLE && tlp_in_valid) begin
        if (is_wr_req) begin
          aw_hdr_wren <= 1; aw_hdr_data <= header_word;
          wr_pay_wren <= 1; wr_pay_data <= tlp_in_data; wr_pay_last <= tlp_in_last;
        end
        else if (is_rd_req) begin
          ar_hdr_wren <= 1; ar_hdr_data <= header_word;
        end
        else if (is_rd_cpl) begin
          rc_hdr_wren <= 1; rc_hdr_data <= header_word;
          rc_pay_wren <= 1; rc_pay_data <= tlp_in_data; rc_pay_last <= tlp_in_last;
        end
      end
      else if (state==PAY && tlp_in_valid) begin
        if (is_wr_req) begin
          wr_pay_wren <= 1; wr_pay_data <= tlp_in_data; wr_pay_last <= tlp_in_last;
        end
        if (is_rd_cpl) begin
          rc_pay_wren <= 1; rc_pay_data <= tlp_in_data; rc_pay_last <= tlp_in_last;
        end
      end
    end
  end

endmodule
