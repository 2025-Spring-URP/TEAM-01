// File: PCIE_PKG.sv
`ifndef __PCIE_PKG_SVH__
`define __PCIE_PKG_SVH__

package PCIE_PKG;

  // 기본 PCIe 관련 상수들
  localparam int ADDR_WIDTH               = 64;     // 64비트 주소
  localparam int PIPE_DATA_WIDTH          = 256;    // 32바이트씩 전송됨
  localparam int MAX_PAYLOAD_SIZE         = 128;    // DW 단위
  localparam int READ_COMPLETION_BOUNDARY = 64;     // DW 단위

  // TLP 포맷/타입 구분용
  localparam logic [2:0] FMT_MEM_RD        = 3'b001;  // Mem Read
  localparam logic [2:0] FMT_MEM_WR        = 3'b011;  // Mem Write
  localparam logic [2:0] FMT_CPL_NO_DATA   = 3'b010;  // Write Completion (no data)
  localparam logic [2:0] FMT_CPL_WITH_DATA = 3'b011;  // Read Completion (with data)
  localparam logic [4:0] TLP_TYPE_CPL      = 5'b01010; // Completion TLP type

  // 기본 ID (변경 필요하면 여기만 고치면 됨)
  localparam logic [15:0] REQUESTER_ID_DEFAULT = 16'h0200;
  localparam logic [15:0] COMPLETER_ID_DEFAULT  = 16'h0000;

  // 4DW Memory Request 헤더 구조체
  typedef struct packed {
    // DW0
    logic [5:0]   addr_l;
    logic [1:0]   reserved;
    logic [23:0]  addr_m;
    logic [31:0]  addr_h;
    logic [7:0]   byte_enable;
    logic [7:0]   tag_l;
    logic [15:0]  requester_id;
    // DW1
    logic [7:0]   length_l;
    logic         td;
    logic         ep;
    logic [1:0]   attr_l;
    logic [1:0]   at;
    logic [1:0]   length_h;
    logic         tag_h;
    logic [2:0]   tc;
    logic         tag_m;
    logic         attr_h;
    logic         ln;
    logic         th;
    logic [2:0]   fmt;
    logic [4:0]   tlp_type;
  } tlp_memory_req_header;

  // 메모리 쓰기 TLP 헤더 생성 함수
  function automatic tlp_memory_req_header create_w_header(
    input logic [63:0] addr,   // 64비트 주소
    input logic [9:0]  length  // 바이트 수
  );
    tlp_memory_req_header hdr;
    hdr.fmt          = FMT_MEM_WR;
    hdr.tlp_type     = 5'b00000;       // Memory Write
    hdr.tag_h        = 1'b0; hdr.tc = 3'b000; hdr.tag_m = 1'b0;
    hdr.attr_h       = 1'b0; hdr.ln = 1'b0;    hdr.th = 1'b0;
    hdr.td           = 1'b0; hdr.ep = 1'b0;
    hdr.attr_l       = 2'b00; hdr.at = 2'b00;
    hdr.reserved     = 2'b00;
    hdr.length_h     = length[9:8];
    hdr.length_l     = length[7:0];
    hdr.requester_id = REQUESTER_ID_DEFAULT;
    hdr.tag_l        = 8'h00;
    hdr.byte_enable  = 8'hFF;           // 4바이트 모두 유효
    // 주소 4바이트 정렬 후 분할
    hdr.addr_h = { addr[39:32], addr[47:40], addr[55:48], addr[63:56] };
    hdr.addr_m = { addr[15:8],  addr[23:16], addr[31:24] };
    hdr.addr_l = addr[7:2];
    return hdr;
  endfunction

  // 메모리 읽기 TLP 헤더 생성 함수
  function automatic tlp_memory_req_header create_r_header(
    input logic [63:0] addr,
    input logic [9:0]  length
  );
    tlp_memory_req_header hdr;
    hdr.fmt          = FMT_MEM_RD;
    hdr.tlp_type     = 5'b00000;       // Memory Read
    hdr.tag_h        = 1'b0; hdr.tc = 3'b000; hdr.tag_m = 1'b0;
    hdr.attr_h       = 1'b0; hdr.ln = 1'b0;    hdr.th = 1'b0;
    hdr.td           = 1'b0; hdr.ep = 1'b0;
    hdr.attr_l       = 2'b00; hdr.at = 2'b00;
    hdr.reserved     = 2'b00;
    hdr.length_h     = length[9:8];
    hdr.length_l     = length[7:0];
    hdr.requester_id = REQUESTER_ID_DEFAULT;
    hdr.tag_l        = 8'h00;
    hdr.byte_enable  = 8'hFF;
    hdr.addr_h = { addr[39:32], addr[47:40], addr[55:48], addr[63:56] };
    hdr.addr_m = { addr[15:8],  addr[23:16], addr[31:24] };
    hdr.addr_l = addr[7:2];
    return hdr;
  endfunction

  // 3DW Completion 헤더 구조체
  typedef struct packed {
    // DW0
    logic            reserved;
    logic [6:0]      lower_addr;
    logic [7:0]      tag;
    logic [15:0]     requester_id;
    logic [7:0]      byte_count_l;
    logic [2:0]      cpl_status;
    logic            bcm;
    logic [3:0]      byte_count_h;
    logic [15:0]     completer_id;
    // DW1
    logic [7:0]      length_l;
    logic            td;
    logic            ep;
    logic [1:0]      attr_l;
    logic [1:0]      at;
    logic [1:0]      length_h;
    logic            tag_h;
    logic [2:0]      tc;
    logic            tag_m;
    logic            attr_h;
    logic            ln;
    logic            th;
    logic [2:0]      fmt;
    logic [4:0]      tlp_type;
  } tlp_cpl_hdr_t;

  // 공통 Completion 생성 함수
  function automatic tlp_cpl_hdr_t gen_tlp_cplx_hdr(
    input logic [2:0]  fmt,
    input logic [4:0]  tlp_type,
    input logic [2:0]  tc,
    input logic        ln,
    input logic        th,
    input logic        td,
    input logic        ep,
    input logic [2:0]  attr,
    input logic [1:0]  at,
    input logic [9:0]  length_dw,
    input logic [15:0] completer_id,
    input logic [2:0]  cpl_status,
    input logic        bcm,
    input logic [11:0] byte_cnt,
    input logic [15:0] requester_id,
    input logic [9:0]  tag,
    input logic [6:0]  lower_addr,
    input logic        reserved_in
  );
    tlp_cpl_hdr_t hdr;
    hdr.fmt           = fmt;
    hdr.tlp_type      = tlp_type;
    hdr.tc            = tc;
    hdr.ln            = ln;
    hdr.th            = th;
    hdr.td            = td;
    hdr.ep            = ep;
    hdr.attr_h        = attr[2];
    hdr.attr_l        = attr[1:0];
    hdr.at            = at;
    hdr.length_h      = length_dw[9:8];
    hdr.length_l      = length_dw[7:0];
    hdr.completer_id  = completer_id;
    hdr.cpl_status    = cpl_status;
    hdr.bcm           = bcm;
    hdr.byte_count_h  = byte_cnt[11:8];
    hdr.byte_count_l  = byte_cnt[7:0];
    hdr.requester_id  = requester_id;
    hdr.tag_h         = tag[9];
    hdr.tag_m         = tag[8];
    hdr.tag           = tag[7:0];
    hdr.lower_addr    = lower_addr;
    hdr.reserved      = reserved_in;
    return hdr;
  endfunction

  // 쓰기 컴플리션 (헤더만)
  function automatic tlp_cpl_hdr_t create_cpl_no_data(
    input logic [9:0] len_dw,
    input logic [9:0] tag_dw,
    input logic [6:0] addr_lower
  );
    return gen_tlp_cplx_hdr(
      FMT_CPL_NO_DATA, TLP_TYPE_CPL,
      3'b000,1'b0,1'b0,1'b0,1'b0,
      3'b000,2'b00,
      len_dw,
      COMPLETER_ID_DEFAULT,
      3'b000,
      1'b0,
      len_dw*4,
      REQUESTER_ID_DEFAULT,
      tag_dw,
      addr_lower,
      1'b0
    );
  endfunction

  // 읽기 컴플리션 (데이터 포함)
  function automatic tlp_cpl_hdr_t create_cpl_with_data(
    input logic [9:0] len_dw,
    input logic [9:0] tag_dw,
    input logic [6:0] addr_lower
  );
    return gen_tlp_cplx_hdr(
      FMT_CPL_WITH_DATA, TLP_TYPE_CPL,
      3'b000,1'b0,1'b0,1'b0,1'b0,
      3'b000,2'b00,
      len_dw,
      COMPLETER_ID_DEFAULT,
      3'b000,
      1'b0,
      len_dw*4,
      REQUESTER_ID_DEFAULT,
      tag_dw,
      addr_lower,
      1'b0
    );
  endfunction

  // RX용 필드 추출 헬퍼
  function automatic logic [63:0] get_addr_from_req_hdr(input tlp_memory_req_header h);
    return {h.addr_h, h.addr_m, h.addr_l, 2'b00};
  endfunction
  function automatic logic [9:0] get_len_dw_from_req_hdr(input tlp_memory_req_header h);
    return {h.length_h, h.length_l};
  endfunction
  function automatic logic [9:0] get_tag_from_req_hdr(input tlp_memory_req_header h);
    return {h.tag_h, h.tag_m, h.tag_l};
  endfunction
  function automatic logic [9:0] get_len_dw_from_cpl_hdr(input tlp_cpl_hdr_t h);
    return {h.length_h, h.length_l};
  endfunction
  function automatic logic [2:0] get_cpl_status_from_cpl_hdr(input tlp_cpl_hdr_t h);
    return h.cpl_status;
  endfunction

endpackage

`endif
