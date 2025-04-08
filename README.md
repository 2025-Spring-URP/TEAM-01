<해야할 일>
AXI4 기반으로 IO가 어떻게 들어오는 지 분석
해당 IO를 어떤 순서로 어떤 방식으로 decoding해서 transaction에 넘겨줄 지 생각
쓰일 변수와 쓰이지 않을 변수를 구분

우선순위 : axi4 측 신호를 decoding 하는 모듈을 제작해야함.(TX단 기준으로)

1. TX단에서는 PCIe 측이 slave로 slave에 대한 IO를 따로 정리 (read, write 별로 따로 정리하면 좋을 거 같음)
   slave IO [       ]

2. RX단에서는 PCIe 측이 master로 추후에 complection 부분 처리하는 경우 따로 정리하기
