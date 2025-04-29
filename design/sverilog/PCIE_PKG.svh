package PCIE_PKG;

    //----------------------------------------------------------
    // PCIe 관련 상수 정의
    //----------------------------------------------------------

    parameter int ADDR_WIDTH       = 64;   // 주소 버스 폭
    parameter int DATA_WIDTH       = 256;  // 데이터 버스 폭
    parameter int MAX_PAYLOAD_SIZE = 128;  // 최대 페이로드 크기 (Byte 단위)

    // 메모리 요청용 TLP 헤더 포맷
    typedef struct packed {
        // byte 0
        logic   [2:0] fmt;        // 포맷 (3DW+데이터 or 3DW)
        logic   [4:0] tlp_type;   // TLP 타입

        // byte 1
        logic         tag_h;      // 태그 상위 비트
        logic   [2:0] tc;          // 트래픽 클래스
        logic         tag_l;      // 태그 하위 비트
        logic         attr_h;     // 속성 상위 비트
        logic         ln;         // 무시
        logic         th;         // 무시

        // byte 2
        logic         td;         // 다이제스트 플래그 (무시)
        logic         ep;         // 에러 포이즌 플래그
        logic   [1:0] attr_l;     // 속성 하위 비트
        logic   [1:0] at;          // 주소 타입
        logic   [1:0] length_h;    // 길이 상위 비트

        // byte 3
        logic   [7:0] length_l;    // 길이 하위 비트

        // byte 4~7
        logic  [15:0] requester_id; // 요청자 BDF ID
        logic   [7:0] tag;           // 태그 값
        logic   [3:0] last_dw_be;    // 마지막 더블워드 Byte Enable
        logic   [3:0] first_dw_be;   // 첫 더블워드 Byte Enable

        // byte 8~11
        logic  [29:0] address;    // 주소 (DW 정렬)
        logic   [1:0] ph;         // 무시
    } tlp_memory_req_header;


    // Memory Write 요청용 헤더 생성 함수
    function automatic tlp_memory_req_header create_w_header(
        input logic [31:0] addr,
        input logic [9:0]  length,
        input logic [15:0] bdf
    );
        tlp_memory_req_header hdr;

        // 포맷: 3DW + 데이터
        hdr.fmt       = 3'b010;
        hdr.tlp_type  = 5'b00000;   // Memory Write

        // 기본 세팅 (특수 기능 미사용)
        hdr.tag_h     = 1'b0;
        hdr.tc        = 3'b000;
        hdr.tag_l     = 1'b0;
        hdr.attr_h    = 1'b0;
        hdr.ln        = 1'b0;
        hdr.th        = 1'b0;

        hdr.td        = 1'b0;
        hdr.ep        = 1'b0;
        hdr.attr_l    = 2'b00;
        hdr.at        = 2'b00;

        // 길이 설정
        hdr.length_h  = length[9:8];
        hdr.length_l  = length[7:0];

        // 요청자 ID, 태그 등 설정
        hdr.requester_id = bdf;
        hdr.tag          = 8'h00;
        hdr.last_dw_be   = 4'b1111;  // 무시
        hdr.first_dw_be  = 4'b1111;  // 전체 DW 사용

        // 주소 (32비트 기준, 4B 정렬)
        hdr.address   = addr[31:2];
        hdr.ph        = 2'b00;

        return hdr;
    endfunction


    // Memory Read 요청용 헤더 생성 함수
    function automatic tlp_memory_req_header create_r_header(
        input logic [31:0] addr,
        input logic [9:0]  length,
        input logic [15:0] bdf
    );
        tlp_memory_req_header hdr;

        // 포맷: 3DW (데이터 없음)
        hdr.fmt       = 3'b000;
        hdr.tlp_type  = 5'b00000;   // Memory Read

        // 기본 세팅 (특수 기능 미사용)
        hdr.tag_h     = 1'b0;
        hdr.tc        = 3'b000;
        hdr.tag_l     = 1'b0;
        hdr.attr_h    = 1'b0;
        hdr.ln        = 1'b0;
        hdr.th        = 1'b0;

        hdr.td        = 1'b0;
        hdr.ep        = 1'b0;
        hdr.attr_l    = 2'b00;
        hdr.at        = 2'b00;

        // 길이 설정
        hdr.length_h  = length[9:8];
        hdr.length_l  = length[7:0];

        // 요청자 ID, 태그 등 설정
        hdr.requester_id = bdf;
        hdr.tag          = 8'h00;
        hdr.last_dw_be   = 4'b1111;  // 전체 DW 사용
        hdr.first_dw_be  = 4'b1111;

        // 주소 (32비트 기준, 4B 정렬)
        hdr.address   = addr[31:2];
        hdr.ph        = 2'b00;

        return hdr;
    endfunction

endpackage
