# stunning-memory

IKEA GRILLPLATS Plug Matter over Thread 엣지 드라이버

[영어 문서 보기](README.en.md)

## Matter 드라이버

이 저장소는 Matter over Thread로 연결된 IKEA GRILLPLATS Plug에서 다음 기능을 제공합니다.

- 전원 켜기·끄기
- 소모 전력: `W`
- 전압: `V`
- 전류: `A`
- 누적 에너지: `Wh`
- 상태 새로 고침

실제 허브 검증값:

- 전력: `146.3 W`
- 전압: `227 V`
- 전류: `0.663 A`
- 에너지: `39 Wh`

## 설치

1. GRILLPLATS Plug를 Matter over Thread 방식으로 초기화하고 SmartThings Station에 연결합니다.
2. 아래 초대 링크로 배포 채널에 참여합니다.
3. `IKEA GRILLPLATS Plug Matter Power` 드라이버를 허브에 설치합니다.
4. 장치 드라이버를 새 Matter 드라이버로 전환합니다.

초대 링크: <https://bestow-regional.api.smartthings.com/invite/Y7236AZwknMr>

## 드라이버 폴더

```text
matter-ikea-grillplats-plug/
├── config.yml
├── fingerprints.yml
├── matter-ikea-grillplats-plug.zip
├── profiles/
│   └── matter-ikea-grillplats-plug.yml
└── src/
    └── init.lua
```

## Matter 식별 정보

```text
Vendor ID: 0x117C
Product ID: 0x1000
전송 방식: Thread
전력 측정 엔드포인트: 2
```

전압·전류·전력은 Matter `ElectricalPowerMeasurement` 클러스터에서 읽고,
누적 에너지는 `ElectricalEnergyMeasurement` 클러스터에서 읽습니다.
