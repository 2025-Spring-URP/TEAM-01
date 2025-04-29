
    // 이 코드는 'AXI4'라는 버스(데이터가 오가는 통로) 규격을 SystemVerilog 인터페이스 형태로
    // 정리해 놓은 것입니다. 'AXI4'는 CPU나 여러 부품들이 메모리나 다른 장치와 정보를
    // 주고받을 때 사용하는 '약속(프로토콜)'이라고 생각할 수 있습니다.

    // 여기엔 4가지 인터페이스가 있습니다.
    //  1. AXI4_A_IF : 주소(어디로 보낼지/어디서 받을지) 정보를 주고받는 채널
    //  2. AXI4_W_IF : 실제 데이터를 쓰는(Write) 채널
    //  3. AXI4_B_IF : 쓰기 응답(Write Response)을 주고받는 채널
    //  4. AXI4_R_IF : 실제 데이터를 읽는(Read) 채널
    //
    // 각 인터페이스에는 'master'(데이터를 요청하거나 보내는 쪽),
    // 'slave'(데이터를 전달받거나 응답을 주는 쪽),
    // 'monitor'(신호를 관찰만 하는 쪽) 이렇게 구분된 연결점이 있습니다.


    // 인터페이스 안에는 'avalid', 'aready', 'wvalid', 'wready' 등의 신호가 있습니다.
    //  - avalid, wvalid, bvalid, rvalid: "지금 보낼 데이터가 준비됐어요!" 라고 말하는 신호
    //  - aready, wready, bready, rready: "네, 이제 받아도 돼요!" 라고 응답해주는 신호
    // 신호 이름에 따라 용도가 조금씩 달라지지만, 기본적으로 'valid'와 'ready'가 함께 손을 잡아
    // 한 번의 데이터 전송이 이뤄진다고 보면 됩니다.
    //

    //
    // ---------------------------------------------------------------------------
    // AXI4_A_IF : 주소 채널 (AW = Write Address, AR = Read Address)
    //
    // - 주소를 담아 보내는 역할
    // - avalid : "주소 보낼 준비 됐다" / aready : "주소 받아줄 준비 됐다"
    // - aid    : 마스터와 슬레이브 간 거래를 구분해주는 ID
    // - aaddr  : 실제로 데이터를 쓰거나 읽을 주소
    // - alen   : 몇 번 버스트(burst)로 전송할지 개수 (AXI에서 연속 전송할 데이터 개수)
    // - asize  : 한 번 전송할 때의 데이터 크기
    // - aburst : 어떤 방식으로 데이터를 연속 전송할 것인지 (예: INCR, WRAP 등)
    // - acache, aprot, aqos, aregion : AXI에서 정의한 추가 기능을 위한 제어 신호
    //
    // ---------------------------------------------------------------------------

    interface AXI4_A_IF
    #(
        parameter   ID_WIDTH                = 4,   // ID 신호의 비트 수
        parameter   ADDR_WIDTH              = 32   // 주소(ADDR) 신호의 비트 수 64로 수정!!
    )
    (
        // 시계(Clock)와 리셋(Reset)은 모든 AXI 신호의 기준이 됨
        input   wire                        aclk,       
        input   wire                        areset_n    
    );

        // 주소 채널에서 사용되는 신호들을 logic으로 선언
        logic                               avalid;   // 주소를 보낼 준비가 되었음을 알림
        logic                               aready;   // 주소를 받아줄 준비가 되었음을 알림
        logic   [ID_WIDTH-1:0]              aid;      // 트랜잭션 식별자
        logic   [ADDR_WIDTH-1:0]            aaddr;    // 주소
        logic   [7:0]                       alen;     // 연속 전송할 데이터 수
        logic   [2:0]                       asize;    // 한 번 전송할 데이터 크기
        logic   [1:0]                       aburst;   // 버스트 방식(INCR/WRAP 등)
        logic   [3:0]                       acache;   // 캐시 관련 속성 - no
        logic   [2:0]                       aprot;    // 보호(protection) 속성 - no
        logic   [3:0]                       aqos;     // QoS(품질 보장) 관련 신호 - no
        logic   [3:0]                       aregion;  // 지역(region) 속성 - no

        // -----------------------------------------------------------------------
        // modport: 이 인터페이스를 master, slave, monitor 각각 다른 역할로 사용
        // -----------------------------------------------------------------------
        modport master (
            // master에서 출력 (valid, 주소, ID 등) / slave에서 입력
            output      avalid, aid, aaddr, alen, asize,
                        aburst, acache, aprot, aqos, aregion,
            // master에서 입력 (aready) / slave에서 출력
            input       aready
        );

        modport slave (
            // slave에서 입력으로 받는 신호들
            input       avalid, aid, aaddr, alen, asize,
                        aburst, acache, aprot, aqos, aregion,
            // slave에서 출력
            output      aready
        );

        modport monitor (
            // 모니터는 avalid, aid, aaddr 등등을 관찰만 함
            input       avalid, aid, aaddr, alen, asize,
                        aburst, acache, aprot, aqos, aregion,
            input       aready
        );

        // -----------------------------------------------------------------------
        // 아래는 시뮬레이션/검증에 도움을 주는 코드들
        // (직접 디자인 기능과는 관계없고, 시뮬레이션에서만 사용)
        // -----------------------------------------------------------------------
        // synopsys translate_off
        int count;  // 몇 번 주소가 전송되었나 세는 변수

        always @(posedge aclk) begin
            if (~areset_n) begin
                count <= 0;
            end
            else if (avalid & aready) begin
                count <= count + 1; // valid와 ready가 동시에 1이면 전송 성공
            end
        end

        // 한 번 valid가 뜨면 ready가 떨 때까지 신호들이 바뀌면 안 된다는 규칙 확인
        // $stable(aid)는 aid가 변하지 않았음을 검사
        astable: assert property (
            @(posedge aclk) disable iff (~areset_n)
            avalid && !aready     |-> ##1 $stable(aid)
                                        && $stable(aaddr)
                                        && $stable(alen)
                                        && $stable(asize)
                                        && $stable(aburst)
                                        && $stable(acache)
                                        && $stable(aprot)
                                        && $stable(aqos)
                                        && $stable(aregion)
        );

        // master와 slave 리셋을 위한 간단한 함수
        function automatic reset_master();
            avalid  = 'd0;
            aid     = 'dx;
            aaddr   = 'dx;
            alen    = 'dx;
            asize   = 'dx;
            aburst  = 'dx;
            acache  = 'dx;
            aprot   = 'dx;
            aqos    = 'dx;
            aregion = 'dx;
        endfunction

        function automatic reset_slave();
            aready  = 'd0;
        endfunction
        // synopsys translate_on

    endinterface

    // ---------------------------------------------------------------------------
    // AXI4_W_IF : 쓰기 데이터(Write Data) 채널
    //
    // - avalid/aready로 주소를 확인한 뒤, 실제 '데이터'를 전송하기 위한 채널
    // - wvalid : "쓰려고 할 데이터 준비됐다" / wready : "데이터 받을 준비 됐다"
    // - wdata  : 실제 쓰여질 데이터
    // - wstrb  : 어느 바이트나 비트를 유효하게 쓸지 알려주는 신호
    // - wlast  : 여러 번에 나눠서 전송할 때, 마지막 전송이라는 것을 알림
    // ---------------------------------------------------------------------------
    interface AXI4_W_IF
    #(
        parameter   ID_WIDTH                = 4,   // 여긴 ID를 쓰지 않아도 되지만, 혹시 모를 확장성
        parameter   DATA_WIDTH              = 64,  // 실제 데이터 폭
        parameter   STRB_WIDTH              = (DATA_WIDTH/8) // strobe 폭(바이트 단위)
    )
    (
        input   wire                        aclk,
        input   wire                        areset_n
    );

        // -----------------------------------------------------------------------
        // 쓰기 데이터 채널에서 사용할 신호들
        // -----------------------------------------------------------------------
        logic                               wvalid;          // 데이터 보낼 준비
        logic                               wready;          // 데이터 받을 준비
        logic   [DATA_WIDTH-1:0]            wdata;           // 전송할 데이터
        logic   [STRB_WIDTH-1:0]            wstrb;           // 바이트 단위로 어느 부분이 유효인지 표시
        logic                               wlast;           // 마지막 데이터인지 표시

        // modport로 master/slave/monitor 각각 구분
        modport master (
            output      wvalid, wdata, wstrb, wlast,
            input       wready
        );

        modport slave (
            input       wvalid, wdata, wstrb, wlast,
            output      wready
        );

        modport monitor (
            input       wvalid, wdata, wstrb, wlast,
            output      wready
        );

        // -----------------------------------------------------------------------
        // 아래는 시뮬레이션/검증용 코드들
        // -----------------------------------------------------------------------
        // synopsys translate_off
        int count;      // 몇 번 데이터 전송이 일어났는지 센다
        int last_count; // 마지막 데이터(wlast=1) 전송이 몇 번 일어났는지 센다

        always @(posedge aclk) begin
            if (~areset_n) begin
                count <= 0;
            end
            else if (wvalid & wready) begin
                count <= count + 1;
            end
        end

        always @(posedge aclk) begin
            if (~areset_n) begin
                last_count <= 0;
            end
            else if (wvalid & wready & wlast) begin
                last_count <= last_count + 1;
            end
        end

        // valid가 떠 있는 동안(ready가 0이면) wdata, wstrb, wlast가 바뀌면 안 되는지 확인
        wstable: assert property (
            @(posedge aclk) disable iff (~areset_n)
            wvalid && !wready     |-> ##1 $stable(wdata)
                                        && $stable(wstrb)
                                        && $stable(wlast)
        );

        // 마찬가지로 master/slave 리셋 함수
        function automatic reset_master();
            wvalid = 'd0;
            wdata  = 'dx;
            wstrb  = 'dx;
            wlast  = 'dx;
        endfunction

        function automatic reset_slave();
            wready = 'd0;
        endfunction
        // synopsys translate_on

    endinterface

    // ---------------------------------------------------------------------------
    // AXI4_B_IF : 쓰기 응답(Write Response) 채널
    //
    // - 데이터를 잘 받았는지, 에러는 없었는지 슬레이브가 마스터에게 알려주는 채널
    // - bvalid : "쓰기를 처리했으니 응답 보낼 준비 됐다" / bready : "응답 받을 준비 됐다"
    // - bid    : 어떤 트랜잭션(거래)에 대한 응답인지 구분하기 위한 ID
    // - bresp  : 응답 결과(OKAY, SLVERR, DECERR 등)
    // ---------------------------------------------------------------------------
    interface AXI4_B_IF
    #(
        parameter   ID_WIDTH                = 4
    )
    (
        input   wire                        aclk,
        input   wire                        areset_n
    );

        logic                               bvalid;
        logic                               bready;
        logic   [ID_WIDTH-1:0]              bid;
        logic   [1:0]                       bresp;

        // master : 응답을 받아보는 쪽
        // slave  : 응답을 만들어주는 쪽
        modport master (
            input       bvalid, bid, bresp,
            output      bready
        );

        modport slave (
            output      bvalid, bid, bresp,
            input       bready
        );

        modport monitor (
            output      bvalid, bid, bresp,
            input       bready
        );

        // -----------------------------------------------------------------------
        // 시뮬레이션/검증용
        // -----------------------------------------------------------------------
        // synopsys translate_off
        int count; // 몇 번 응답이 발생했는지 센다

        always @(posedge aclk) begin
            if (~areset_n) begin
                count <= 0;
            end
            else if (bvalid & bready) begin
                count <= count + 1;
            end
        end

        // 응답 신호가 유효한 동안 bready가 내려갈 때, bid, bresp가 바뀌면 안 된다는 것 확인
        bstable: assert property (
            @(posedge aclk) disable iff (~areset_n)
            bvalid && !bready     |-> ##1 $stable(bid)
                                        && $stable(bresp)
        );

        // 리셋 함수
        function automatic reset_master();
            bready = 'd0;
        endfunction

        function automatic reset_slave();
            bvalid = 'd0;
            bid    = 'dx;
            bresp  = 'dx;
        endfunction
        // synopsys translate_on

    endinterface

    // ---------------------------------------------------------------------------
    // AXI4_R_IF : 읽기 데이터(Read Data) 채널
    //
    // - 슬레이브에서 마스터로 데이터를 보내는 채널
    // - rvalid : "읽어줄 데이터 준비됐다" / rready : "데이터 받을 준비 됐다"
    // - rid    : 어떤 트랜잭션(거래)에 대한 데이터인지 구분
    // - rdata  : 실제 읽을 데이터
    // - rresp  : 읽기 응답(OKAY, SLVERR 등)
    // - rlast  : 여러 번 나눠 읽을 때, 이번이 마지막 데이터인지 표시
    // ---------------------------------------------------------------------------
    interface AXI4_R_IF
    #(
        parameter   ID_WIDTH                = 4,
        parameter   DATA_WIDTH              = 64
    )
    (
        input   wire                        aclk,
        input   wire                        areset_n
    );

        logic                               rvalid;
        logic                               rready;
        logic   [ID_WIDTH-1:0]              rid;
        logic   [DATA_WIDTH-1:0]            rdata;
        logic   [1:0]                       rresp;
        logic                               rlast;

        // master : 데이터를 받아가는 쪽
        // slave  : 데이터를 주는 쪽
        modport master (
            input       rvalid, rid, rdata, rresp, rlast,
            output      rready
        );

        modport slave (
            output      rvalid, rid, rdata, rresp, rlast,
            input       rready
        );

        modport monitor (
            output      rvalid, rid, rdata, rresp, rlast,
            input       rready
        );

        // -----------------------------------------------------------------------
        // 시뮬레이션/검증용
        // -----------------------------------------------------------------------
        // synopsys translate_off
        int count;      // 몇 번 읽기 데이터가 전달되었는지
        int last_count; // 마지막 데이터(rlast=1)가 전달된 횟수

        always @(posedge aclk) begin
            if (~areset_n) begin
                count <= 0;
            end
            else if (rvalid & rready) begin
                count <= count + 1;
            end
        end

        always @(posedge aclk) begin
            if (~areset_n) begin
                last_count <= 0;
            end
            else if (rvalid & rready & rlast) begin
                last_count <= last_count + 1;
            end
        end

        // valid 떠 있는 동안(ready가 0이면) rdata, rresp 등은 바뀌면 안 됨
        rstable: assert property (
            @(posedge aclk) disable iff (~areset_n)
            rvalid && !rready     |-> ##1 $stable(rid)
                                        && $stable(rdata)
                                        && $stable(rresp)
                                        && $stable(rlast)
        );

        // 리셋 함수
        function automatic reset_master();
            rready = 'd0;
        endfunction

        function automatic reset_slave();
            rvalid = 'd0;
            rid    = 'dx;
            rdata  = 'dx;
            rresp  = 'dx;
            rlast  = 'dx;
        endfunction
        // synopsys translate_on

    endinterface
