# stunning-memory
IKEA GRILLPLATS Plug 지그비 엣지 드라이버

## 목적

IKEA `GRILLPLATS Plug`가 일반 조광기 드라이버로 잘못 인식되거나
`NONFUNCTIONAL` 상태가 되는 문제를 보완하기 위한 전용 SmartThings Edge 드라이버입니다.

## 지원 기능

- 전원 켜기
- 전원 끄기
- 실제 전원 상태 보고
- 상태 새로 고침
- 전류값: `A`
- 소모 전력: `W`
- 전압: `V`

밝기 조절 기능은 플러그 장치에 맞지 않으므로 포함하지 않습니다.

## 갱신 방식

전류·소모 전력·전압은 지그비 `ElectricalMeasurement` 클러스터에서 읽습니다.

- 전압: `RMSVoltage` (`0x0505`)
- 전류: `RMSCurrent` (`0x0508`)
- 소모 전력: `ActivePower` (`0x050B`)
- 지그비 보고 요청: 최소 1초, 최대 60초
- 주기 읽기: 60초마다 재조회
- 앱에서 `새로 고침` 실행 시 즉시 재조회

장치가 보고하는 배율과 나눗셈 값이 있으면 이를 사용해 실제 단위로 변환합니다.

## 지원 지문

```text
제조사: IKEA of Sweden
모델: GRILLPLATS Plug
연결 방식: 지그비
```

## 설치와 장치 전환

1. SmartThings CLI로 드라이버 패키지를 업로드합니다.
2. 드라이버를 채널에 배정합니다.
3. SmartThings Station 허브를 채널에 등록합니다.
4. 허브에 드라이버를 설치합니다.
5. 기존 `Generic Dimmer` 장치의 드라이버를 `IKEA GRILLPLATS Plug Power`로 전환합니다.

허브에 드라이버를 설치하는 것과 기존 장치가 새 드라이버를 사용하는 것은 별도 단계입니다.
장치 전환 뒤에도 값이 비어 있으면 허브 로그에서 `ElectricalMeasurement` 보고 여부를 확인해야 합니다.

## 폴더 구성

```text
zigbee-ikea-grillplats-plug/
├── config.yml
├── fingerprints.yml
├── ikea-grillplats-plug.zip
├── profiles/
│   └── ikea-grillplats-plug.yml
└── src/
    └── init.lua
```

## 출처

이 프로젝트는 아래 공개 저장소의 SmartThings Edge 지그비 드라이버 구조와 구현 방식을 참고했습니다.

- 참고 저장소: <https://github.com/Mariano-Github/Edge-Drivers-Beta>
- 참고 저장소 작성자: Mariano-Github

이 저장소의 `zigbee-ikea-grillplats-plug`는 IKEA GRILLPLATS Plug용으로 별도 작성한 드라이버입니다.
실제 원본 파일을 직접 가져오거나 수정하는 경우에는 원본 저장소의 Apache-2.0 라이선스 고지를 유지해야 합니다.
