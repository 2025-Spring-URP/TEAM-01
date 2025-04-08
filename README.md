<해야할 일>
AXI4 기반으로 IO가 어떻게 들어오는 지 분석
해당 IO를 어떤 순서로 어떤 방식으로 decoding해서 transaction에 넘겨줄 지 생각
쓰일 변수와 쓰이지 않을 변수를 구분

우선순위 : axi4 측 신호를 decoding 하는 모듈을 제작해야함.(TX단 기준으로)

1. TX단에서는 PCIe 측이 slave로 slave에 대한 IO를 따로 정리 (read, write 별로 따로 정리하면 좋을 거 같음)
   slave IO [       ]
  
    logic   [3:0]                       acache;   // 캐시 관련 속성
    logic   [2:0]                       aprot;    // 보호(protection) 속성
    logic   [3:0]                       aqos;     // QoS(품질 보장) 관련 신호
    logic   [3:0]                       aregion;  // 지역(region) 속성
   해당 변수들은 사용하지 않을 예정인지 질문드리기. 만약 사용한다고 해도 그냥 간단히 IO만 top 모듈에 설정해두기.

   write 명령인 경우 clock 별 input 값 정리(우선 여기서 헤더 부분에 필요한 부분만 만들어서 TLP를 만들기 - TLP 담당자에게 의견 전달 필요)
   (또한, cycle의 경우 한 rising edge를 의미하는 건 아니고 vaild가 할당되었을 경우에 다음 사이클로 넘어가는 구조)
   
   ![image](https://github.com/user-attachments/assets/f49a55bb-74fe-4134-830f-ad6e73b73827)

   read 명령인 경우 clock 별 input 값 정리(마찬가지로 cycle의 경우 한 rising edge를 의미하는 건 아니고 vaild가 할당되었을 경우에 다음 사이클로 넘어가는 구조)
   
   ![image](https://github.com/user-attachments/assets/19b8dfb8-3945-4e74-a553-a3b4f0f94573)



3. RX단에서는 PCIe 측이 master로 추후에 complection 부분 처리하는 경우 따로 정리하기
