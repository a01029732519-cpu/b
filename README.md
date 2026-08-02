# ASMR Clicker (Roblox)

느긋하게 클릭하며 힐링하는 Roblox ASMR 클리커 게임입니다. 각 플레이어는 자신만의 전용 구역(Plot)과 오브(Orb)를 받고, 오브를 클릭할 때마다 부드러운 스퀴시 애니메이션 + 리플 이펙트 + ASMR 사운드(팝/슬라임/버블랩/모래 등)가 재생됩니다. 포인트를 모아 클릭 파워, 오브 스킨(사운드 팩 포함), 자동 수익을 주는 ASMR 헬퍼를 구매할 수 있습니다.

## 주요 기능

- **개인 전용 클릭 모델 & 플롯**: 플레이어마다 독립된 구역에 스폰되어 자신만의 클릭 오브젝트를 클릭합니다 (다른 플레이어의 오브젝트도 도와서 클릭 가능).
- **ASMR 클릭 피드백**: 클릭 시 눌렸다 튕기는 스퀴시 트윈, 확산되는 링 이펙트, 스킨별 랜덤 사운드(피치 변주 포함)가 즉시 재생됩니다.
- **진짜 뽁뽁이(Pop-It) 모델**: `Bubble Wrap` 스킨은 단순 색깔 구슬이 아니라 **레인보우 범프(돌기) 그리드**로 렌더링됩니다. 범프 하나하나를 개별 클릭해서 눌러 터뜨릴 수 있고(각자 포인트 지급), 판 전체를 다 누르면 콤보 보너스 포인트 + 축하 이펙트와 함께 판이 리셋되어 무한 반복 가능합니다.
- **스킨 시스템**: Slime / Bubble Wrap(Pop-It 그리드) / Kinetic Sand / Cloud Foam — 스킨마다 모양, 색상, 재질, 전용 클릭 사운드 팩이 다릅니다.
- **업그레이드**: 클릭당 포인트를 늘리는 Click Power 업그레이드.
- **ASMR 헬퍼**: 4초마다 자동으로 포인트를 생성하고 은은한 사운드를 재생하는 패시브 아이템(고양이 골골송, 빗소리 등).
- **오디오 설정**: 배경음악/효과음 볼륨을 각각 조절하는 슬라이더 (ASMR 게임 특성상 사운드 컨트롤을 전면에 배치).
- **데이터 저장**: `DataStoreService`로 포인트, 업그레이드, 보유 스킨/헬퍼, 오디오 설정을 자동/종료 시 저장.
- **기본 안티 익스플로잇**: 서버에서 초당 클릭 수를 제한(`GameConfig.MaxClicksPerSecond`).

## 프로젝트 구조 (Rojo)

```
default.project.json
src/
  ReplicatedStorage/Modules/GameConfig.lua   -- 스킨/업그레이드/헬퍼/사운드 설정 (공유)
  ServerScriptService/Server/
    init.server.lua    -- 메인 서버 로직 (플레이어 접속, 클릭 처리, 구매, 저장)
    PlayerData.lua      -- DataStore 로드/저장
    OrbService.lua       -- 플롯/클릭 모델 생성 (볼 오브 또는 뽁뽁이 그리드), 스킨 리빌드
    PlotManager.lua       -- 플레이어별 플롯 슬롯 배정
  StarterPlayer/StarterPlayerScripts/ASMRClient/
    init.client.lua     -- 클라이언트 진입점 (HUD, 오브 훅업, 배경음악)
    UI.lua                -- HUD/상점/설정 UI 빌드 및 갱신
    Effects.lua            -- 클릭 시 로컬 비주얼/사운드 피드백
```

## Roblox Studio에서 실행하기

1. [Rojo](https://rojo.space/)를 설치합니다 (VS Code 확장 또는 CLI).
2. 이 저장소를 로컬에 clone/pull 합니다.
3. Roblox Studio에서 새 place(또는 기존 place)를 열고 Rojo 플러그인으로 `default.project.json`에 Connect 합니다.
   - CLI: `rojo serve` 실행 후 Studio의 Rojo 플러그인에서 Connect.
4. Studio 메뉴 `Home > Game Settings > Security`에서 **Enable Studio Access to API Services**를 켜야 `DataStoreService`가 테스트 환경에서 동작합니다.
5. Play(F5)로 테스트합니다. 여러 클라이언트를 시뮬레이션하려면 `Test > Local Server` 기능으로 다중 플레이어 테스트를 해보세요.

## 사운드 에셋 교체 (중요)

기본값은 Roblox 클라이언트 내장 사운드(`rbxasset://sounds/...`)를 사용해 업로드 없이 바로 동작하도록 했습니다. 진짜 ASMR 감성을 원한다면 `src/ReplicatedStorage/Modules/GameConfig.lua`의 `Skins[*].ClickSounds`, `Helpers[*].Sound`, `AmbientMusic` 값을 직접 업로드한 사운드의 `rbxassetid://<id>`로 교체하세요. Creator Marketplace(Toolbox)에서 "ASMR", "slime squish", "bubble wrap pop", "kinetic sand" 등으로 검색하면 관련 SFX를 찾을 수 있습니다.

## 커스터마이징 포인트

- `GameConfig.ClickUpgrades` / `GameConfig.Skins` / `GameConfig.Helpers` 테이블에 항목을 추가하면 상점 UI와 서버 로직에 자동 반영됩니다.
- `GameConfig.BubbleWrapGrid`로 뽁뽁이 판의 행/열 개수, 범프 크기, 줄무늬 색상, 클리어 보너스 배율을 조정할 수 있습니다.
- 새 스킨에 `ModelType = "BubbleWrap"`을 지정하면 그 스킨도 뽁뽁이 그리드로 렌더링됩니다 (지정 안 하면 기본 볼 오브).
- `OrbService.lua`의 `PLOT_SPACING`으로 플레이어 간 플롯 간격을 조정할 수 있습니다.
- `GameConfig.MaxClicksPerSecond`로 클릭 속도 제한(안티 익스플로잇)을 조정할 수 있습니다.
