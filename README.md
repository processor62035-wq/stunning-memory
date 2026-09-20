# stunning-memory

IKEA GRILLPLATS Plug 지그비 엣지 드라이버

[영어 문서 보기](README.en.md)

## Matter 드라이버

Matter over Thread로 연결한 장치에는 `matter-ikea-grillplats-plug` 전용 드라이버를 사용할 수 있습니다.

- 전원 켜기·끄기
- 소모 전력: `W`
- 전압: `V`
- 전류: `A`
- 누적 에너지: `Wh`

실제 허브 검증값: 전력 `146.3 W`, 전압 `227 V`, 전류 `0.663 A`, 에너지 `39 Wh`.

지그비 드라이버가 아니라 Matter 장치를 새로 등록한 뒤, Matter 드라이버를 선택해야 합니다.

## 중요: 지그비 모드 활성화

이 드라이버는 **IKEA GRILLPLATS Plug의 지그비 모드 전용**입니다.
와이파이 모드나 클라우드 방식으로 연결된 장치에는 사용할 수 없습니다.

1. SmartThings Station 허브가 온라인인지 확인합니다.
2. 아래 초대 링크를 스마트싱스 앱 또는 휴대폰 브라우저에서 엽니다.
3. 채널 참여를 승인하고 `IKEA GRILLPLATS Plug Power` 드라이버를 허브에 설치합니다.
4. 기존 장치의 드라이버를 `IKEA GRILLPLATS Plug Power`로 전환합니다.
5. 장치 화면에서 전원, 전류, 소모 전력, 전압 값이 표시되는지 확인합니다.

초대 링크: <https://bestow-regional.api.smartthings.com/invite/Y7236AZwknMr>

장치가 계속 `Generic Dimmer`로 표시되거나 `NONFUNCTIONAL` 상태이면,
기존 장치를 삭제한 뒤 지그비 모드로 다시 페어링하고 새 드라이버를 선택해야 할 수 있습니다.

## GRILLPLATS의 지그비 모드 켜기

GRILLPLATS는 기본적으로 Matter over Thread 제품으로 판매되며, 지그비 모드는 공식 설치 화면에 표시되지 않는 숨은 호환 모드입니다.
따라서 아래 순서는 제품 펌웨어에 따라 동작하지 않을 수 있습니다.

1. 플러그를 전원에 연결합니다.
2. 플러그의 전원 버튼을 약 10초 동안 길게 눌러 초기화합니다.
3. 빨간 불이 깜박인 뒤 초기화가 끝날 때까지 기다립니다. 일부 제품은 빨간 불 뒤 흰 불이 켜집니다.
4. 버튼을 빠르게 8번 누릅니다.
5. SmartThings Station에서 새 지그비 장치 검색을 시작하고 `IKEA GRILLPLATS Plug Power`를 선택합니다.

8번 입력만으로 검색되지 않으면 일부 펌웨어에서 보고된 보조 순서인 `4번 빠르게 누르기 → 8번 빠르게 누르기`를 시도합니다.
버튼 입력 뒤에는 검색을 계속 유지하고, 기존 Matter 장치 등록이 남아 있으면 먼저 삭제합니다.

이 모드는 IKEA의 일반 Matter 설치 절차가 아닌 비공식 호환 기능입니다.
지그비 모드에서는 모델과 펌웨어에 따라 전류·전압·소모 전력 측정 클러스터가 제공되지 않을 수 있습니다.

참고:

- <https://www.zigbee2mqtt.io/devices/E2435.html>
- <https://www.ikea.com/se/sv/p/grillplats-stickpropp-smart-60604238/>

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
- 지그비 보고 요청: 설정한 자동 갱신 범위에 맞춰 적용
- 기본 주기: 5~10초 사이에서 가변
- 앱에서 `새로 고침` 실행 시 즉시 재조회

앱의 기기 설정에서 다음 방식을 선택할 수 있습니다.

- 가변 (5~10초 가변): 기본값
- 가변 (5~30초 가변)
- 5초, 고정
- 10초, 고정
- 30초, 고정
- 60초, 고정
- 사용안함 (수동전용)

`사용안함 (수동전용)`을 선택하면 자동 지그비 보고와 주기 읽기를 끄고,
앱의 `새로 고침`을 눌렀을 때만 값을 읽습니다.

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

## 배포 초대

SmartThings 앱에서 아래 초대 링크를 열어 채널에 참여한 뒤 드라이버를 설치할 수 있습니다.

<https://bestow-regional.api.smartthings.com/invite/Y7236AZwknMr>

초대 코드: `Y7236AZwknMr`

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
