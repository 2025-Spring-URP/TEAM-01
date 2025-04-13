`timescale 1ns/1ps

//write까지 구현 완료

module top #(
    parameter ID_WIDTH   = 4,   //id가 따로 의미가 있진 않다고 하셨음음
    parameter ADDR_WIDTH = 32, //주소는 32로 고정한다고 생각각
    parameter DATA_WIDTH = 256,
    parameter CHUNK_MAX_BEATS = 4 //32B씩 128B까지 받을 수 있음음
)(
    
    input  wire                          clk,
    input  wire                          rst_n,

    // ------------------------------------------------------------------------
    // AXI Write Address (AW) 신호들
    //  - master → slave 방향
    // ------------------------------------------------------------------------
    input  wire                          awvalid_in,   // 주소 valid
    output wire                          awready_out,  // 주소 ready
    input  wire [ID_WIDTH-1:0]          awid_in,
    input  wire [ADDR_WIDTH-1:0]        awaddr_in,
    input  wire [7:0]                   awlen_in,   //wdata를 몇 번 보낼 지 알려줌 3이면 4번 보내줌
    input  wire [2:0]                   awsize_in,  //wdata의 사이즈를 지정 우린 2^5로 고정할 듯듯
    input  wire [1:0]                   awburst_in, //burst 타입인데 increse라서 우리는 주소를 n씩 증가시킬거임
    // 필요하면 acache, aprot, aqos, aregion 등을 추가 포트로 두어도 됨

    // ------------------------------------------------------------------------
    // AXI Write Data (W) 신호들
    //  - master → slave
    // ------------------------------------------------------------------------
    input  wire                          wvalid_in,    // Write data valid
    output wire                          wready_out,   // Write data ready
    input  wire [DATA_WIDTH-1:0]        wdata_in,   //32B 즉 256bit씩 wdata가 들어옴옴
    // wstrb 등도 필요하면 추가인데 우리는 안쓸 거임임
    input  wire                          wlast_in,  //한 명령에 대한 마지막 wdata가 들어오면 신호 인가

    // ------------------------------------------------------------------------
    // 디코딩 결과 출력(이 모듈에서 생성) 여기는 write 부분의 아웃풋과 인풋만 정의됨 아마 read인 경우 값이 좀 더 추가될 수도?
    // ------------------------------------------------------------------------
    output wire [ADDR_WIDTH-1:0]        out_addr,
    output wire [7:0]                   out_length,
    output wire [15:0]                  out_bdf,
    output wire                         out_is_memwrite,
    output wire [DATA_WIDTH*CHUNK_MAX_BEATS-1:0] out_wdata,
    output wire                         out_valid,
    input  wire                         out_ready
);

    // ------------------------------------------------------------------------
    // 1) AXI 인터페이스 인스턴스화
    //   : SystemVerilog interface를 Top 내부에서 하나씩 만든다.
    // ------------------------------------------------------------------------
    AXI4_A_IF #(ID_WIDTH, ADDR_WIDTH) i_axi_aw (
        .aclk     (clk),
        .areset_n (rst_n)
    );

    AXI4_W_IF #(ID_WIDTH, DATA_WIDTH) i_axi_w (
        .aclk     (clk),
        .areset_n (rst_n)
    );

    // ------------------------------------------------------------------------
    // 2) Top 레벨 포트와 Interface 신호들 연결 (배선)
    //    - AW쪽: (master→slave) 방향
    // ------------------------------------------------------------------------
    // AW valid, ID, addr, len, etc. -> i_axi_aw.(avalid, aid, aaddr, ...)
    assign i_axi_aw.avalid  = awvalid_in;
    assign i_axi_aw.aid     = awid_in;
    assign i_axi_aw.aaddr   = awaddr_in;
    assign i_axi_aw.alen    = awlen_in;
    assign i_axi_aw.asize   = awsize_in;
    assign i_axi_aw.aburst  = awburst_in;
    // acache, aprot, aqos, aregion 등을 쓰려면 비슷하게 assign

    // slave 출력(aready)을 top 포트로
    assign awready_out      = i_axi_aw.aready;

    // ------------------------------------------------------------------------
    // 3) W쪽: (master→slave) 방향
    // ------------------------------------------------------------------------
    assign i_axi_w.wvalid   = wvalid_in;
    assign i_axi_w.wdata    = wdata_in;
    assign i_axi_w.wlast    = wlast_in;
    // wstrb, etc.

    assign wready_out       = i_axi_w.wready;

    // ------------------------------------------------------------------------
    // 4) 디코딩 모듈 인스턴스 (axi4_if_decoding)
    //    - 이 모듈이 AW/W 인터페이스의 slave modport를 받아서 동작
    // ------------------------------------------------------------------------
    axi4_if_decoding #(
        .ID_WIDTH       (ID_WIDTH),
        .ADDR_WIDTH     (ADDR_WIDTH),
        .DATA_WIDTH     (DATA_WIDTH),
        .CHUNK_MAX_BEATS(CHUNK_MAX_BEATS)
    ) dec_inst (
        .clk       (clk),
        .rst_n     (rst_n),

        // slave modport 연결
        .s_axi_aw  (i_axi_aw.slave),
        .s_axi_w   (i_axi_w.slave),

        // 출력
        .out_addr       (out_addr),
        .out_length     (out_length),
        .out_bdf        (out_bdf),
        .out_is_memwrite(out_is_memwrite),
        .out_wdata      (out_wdata),
        .out_valid      (out_valid),
        .out_ready      (out_ready)
    );

endmodule
