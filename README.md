# Gichan Abba Mobile

Flutter 대시보드 앱 (보기 전용 클라이언트)

## 프로젝트 구분

| 프로젝트 | 경로 | 역할 |
|---|---|---|
| **Gichan_Abba_Mobile** (이 저장소) | `C:\Users\Master\Desktop\Projects\Gichan_Abba_Mobile` | Flutter APK 클라이언트 |
| **Gichan_Abba_System** | `C:\Users\Master\Desktop\Projects\Gichan_Abba_System` | Windows 서버 소스 경로 |

- 이 앱은 보기 전용 대시보드입니다.
- 서버/Oracle/KIS/API 연결은 기본값에서 비활성입니다.
- 매수/매도/주문/제어 버튼이 없습니다.
- 자동매매 서버의 `trade`, `risk`, `order`, `scanner`, `strategy` 모듈을 import하지 않습니다.
- Oracle 배포 경로는 `/opt/gichan_abba/Gichan_Abba_System`이며, Windows 로컬 경로와 혼동하지 않습니다.
- Oracle 배포 경로는 `/opt/gichan_abba/Gichan_Abba_System`이며, Windows 로컬 경로와 혼동하지 않습니다.

## 데이터 소스

기본값은 mock asset입니다.

- mock: `assets/mock/paper_account_snapshot.json`
- api: `DASHBOARD_API_BASE_URL + /snapshot/account`

`lib/config.dart`는 값을 코드에 직접 박지 않고 `--dart-define`으로만 받습니다.

| dart-define 키 | 기본값 | 설명 |
|---|---:|---|
| `SNAPSHOT_SOURCE` | `mock` | `mock` 또는 `api` |
| `DASHBOARD_API_BASE_URL` | 빈 값 | dashboard_api 서버 주소, trailing slash 없이 입력 |
| `DASHBOARD_READ_TOKEN` | 빈 값 | `/snapshot/account` read-only 토큰 |

## 실행 예시

### Mock 모드

`SNAPSHOT_SOURCE`를 지정하지 않으면 mock asset을 사용합니다.

```bash
flutter run
```

명시적으로 mock을 지정할 수도 있습니다.

```bash
flutter run --dart-define=SNAPSHOT_SOURCE=mock
```

### API 모드

Oracle 배포 이후에만 사용합니다. 실제 토큰은 코드나 README에 기록하지 말고 실행/빌드 시점에 주입합니다.

```bash
flutter run \
  --dart-define=SNAPSHOT_SOURCE=api \
  --dart-define=DASHBOARD_API_BASE_URL=https://your-domain.example \
  --dart-define=DASHBOARD_READ_TOKEN=YOUR_READ_ONLY_TOKEN
```

Release APK 빌드도 같은 방식입니다.

```bash
flutter build apk --release \
  --dart-define=SNAPSHOT_SOURCE=api \
  --dart-define=DASHBOARD_API_BASE_URL=https://your-domain.example \
  --dart-define=DASHBOARD_READ_TOKEN=YOUR_READ_ONLY_TOKEN
```


## dashboard_api 연결 준비

Oracle 배포 후 Flutter API mode는 서버의 read-only endpoint만 읽습니다.

- health check: `GET /health`
- account snapshot: `GET /snapshot/account`
- status snapshot: `GET /snapshot/status`

서버는 `/opt/gichan_abba/Gichan_Abba_System` 기준으로 배포하고, systemd 예시는 서버 프로젝트의 `deploy/dashboard_api.service`를 사용합니다.

API token은 서버의 `DASHBOARD_READ_TOKEN` 환경변수와 Flutter의 `--dart-define=DASHBOARD_READ_TOKEN=...` 값으로만 맞춥니다. 실제 token/baseUrl은 이 README나 Dart 코드에 저장하지 않습니다.


## Oracle 배포 후 체크포인트

API mode로 APK를 빌드하기 전에 서버에서 다음을 먼저 확인합니다.

1. `dashboard_api.service` 실행 상태 확인.
2. `GET /health`에서 `read_only=true`, `token_required=true`, `snapshot_path=data/runtime/paper_account_snapshot.json` 확인.
3. `GET /snapshot/account`가 read token 없이 거부되는지 확인.
4. `GET /snapshot/account`가 read token 포함 시 snapshot JSON을 반환하는지 확인.
5. Flutter는 `SNAPSHOT_SOURCE=api`를 넣은 빌드에서만 API를 호출하고, 기본 실행은 mock인지 확인.
6. API 실패, 인증 실패, snapshot 파싱 실패 시 앱은 mock fallback 정책을 사용합니다.

## Oracle 배포 후 API mode 확인 순서

1. Flutter 기본 실행은 mock인지 먼저 확인합니다.

```bash
flutter run
```

2. Oracle 서버에서 `dashboard_api.service`가 실행 중인지 확인합니다.
3. 서버 `GET /health`에서 다음 필드를 확인합니다.
   - `read_only=true`
   - `token_required=true`
   - `snapshot_path=data/runtime/paper_account_snapshot.json`
   - `snapshot_valid=true`
   - `snapshot_error=null`
4. `GET /snapshot/account`가 token 없이 거부되는지 확인합니다.
5. `GET /snapshot/account`와 `GET /snapshot/status`가 read-only token 포함 시 응답하는지 확인합니다.
6. Flutter API mode는 dart-define으로만 실행합니다.

```bash
flutter run \
  --dart-define=SNAPSHOT_SOURCE=api \
  --dart-define=DASHBOARD_API_BASE_URL=https://your-domain.example \
  --dart-define=DASHBOARD_READ_TOKEN=YOUR_READ_ONLY_TOKEN
```

연결 실패 시 확인할 항목:

- `dashboard_api.service` 실행 상태
- Oracle 보안 목록/firewall의 포트 `8765`
- `DASHBOARD_API_BASE_URL` 값
- 서버 `.env`의 read-only token과 Flutter `DASHBOARD_READ_TOKEN` 일치 여부
- `/health`의 `snapshot_valid`와 `snapshot_error`

## Windows 로컬 API mode 테스트

Oracle 배포 전 로컬 Windows에서만 확인하는 절차입니다. 기본 실행은 계속 mock입니다.

1. 서버 프로젝트에서 로컬 dashboard API를 실행합니다.

```powershell
cd "C:\Users\Master\Desktop\Projects\Gichan_Abba_System"
& ".venv\Scripts\python.exe" -m uvicorn dashboard_api:app --host 127.0.0.1 --port 8765
```

2. 브라우저 또는 PowerShell에서 `/health`를 먼저 확인합니다.

```powershell
Invoke-RestMethod http://127.0.0.1:8765/health
```

3. token 인증을 확인합니다.

```powershell
Invoke-WebRequest http://127.0.0.1:8765/snapshot/account
Invoke-RestMethod http://127.0.0.1:8765/snapshot/account -Headers @{ Authorization = "Bearer YOUR_READ_ONLY_TOKEN" }
```

4. PC에서 Flutter를 API mode로 실행합니다.

```powershell
flutter run \
  --dart-define=SNAPSHOT_SOURCE=api \
  --dart-define=DASHBOARD_API_BASE_URL=http://127.0.0.1:8765 \
  --dart-define=DASHBOARD_READ_TOKEN=YOUR_READ_ONLY_TOKEN
```

주의:

- Windows desktop에서 Flutter를 실행할 때: `DASHBOARD_API_BASE_URL=http://127.0.0.1:8765`
- Android emulator에서 PC의 로컬 API에 붙을 때: `DASHBOARD_API_BASE_URL=http://10.0.2.2:8765` 사용 가능 여부를 확인합니다.
- Android real device에서 `127.0.0.1`은 PC가 아니라 기기 자신을 가리킵니다.
- Android real device 테스트는 같은 네트워크의 PC LAN IP 또는 나중에 HTTPS URL을 사용합니다.
- PC LAN IP를 쓸 때는 Windows 방화벽과 같은 네트워크 여부를 확인합니다.
- 직접 `http://...:8765` 연결은 로컬/임시 테스트용이며, Android cleartext 정책 영향을 받을 수 있습니다.
- 연결 실패 시 서버 실행 상태, URL, token, `/health`의 `snapshot_valid`, Android cleartext 정책을 확인합니다.

## 운영 대시보드 화면 구성

Flutter 화면은 read-only 운영 모니터링 카드형 UI입니다.

표시 영역:

- 상단 운영 상태: 데이터 소스(`mock` / `api` / `api -> mock fallback`), `broker_mode`, `read_only`, `KIS API BLOCKED`, `real_order_enabled`, 마지막 업데이트 시간
- 계좌 요약: 총 평가금액, 현금, 보유 평가금액, 실현손익, 평가손익, 수익률, 거래비용
- 리스크/안전 상태: read-only dashboard, order disabled, KIS blocked, PaperBroker mode, API/fallback warning
- 보유 포지션: 종목명/종목코드, 보유수량, 평균단가, 현재가, 평가손익, 수익률, 보유시간
- Watchlist / 후보 종목: symbol, display_name, current_price, change_pct, stage_status, reason, updated_at
- 최근 체결 내역: 시간, 종목, 수량, 매수, 매도, 수익금, 수익률, 거래비용

화면 원칙:

- 매수/매도/주문/제어 버튼 없음
- API 실패 시 mock fallback과 warning 표시 유지
- 자동매매 서버의 주문/리스크/브로커/KIS 모듈 import 금지
- 기본 실행은 mock이며, API 호출은 `SNAPSHOT_SOURCE=api`일 때만 수행
## Android 실행환경 준비

Android emulator 또는 APK 빌드를 확인하려면 Flutter가 Android SDK를 먼저 인식해야 합니다.
현재 `No Android SDK found`가 나오면 앱 코드 문제가 아니라 Android SDK/toolchain 미설치 또는 경로 미설정 문제입니다.

필수 설치 항목:

- Android Studio 또는 독립 Android SDK
- Android SDK Platform
- Android SDK Command-line Tools
- Android SDK Platform-Tools (`adb` 포함)
- Android Emulator
- Android SDK Build-Tools
- Flutter가 인식할 수 있는 SDK 경로, 기본 예: `C:\Users\Master\AppData\Local\Android\Sdk`

SDK를 별도 경로에 설치한 경우 Flutter에 경로를 알려줍니다.

```powershell
flutter config --android-sdk "C:\path\to\Android\Sdk"
```

설치 후 재확인 순서:

```powershell
flutter doctor -v
flutter devices
flutter emulators
flutter build apk --debug
```

정상 기대값:

- `flutter doctor -v`에서 Android toolchain이 `[√]` 상태
- `adb`, `emulator`, `sdkmanager`, `avdmanager`가 사용 가능
- `flutter emulators`에서 생성된 AVD가 표시됨
- `flutter devices`에서 emulator 또는 실기기가 표시됨
- `flutter build apk --debug`가 Android SDK 오류 없이 진행됨

Android emulator 테스트 조건:

- Android Studio Device Manager 또는 `avdmanager`로 AVD 생성
- PC의 로컬 dashboard_api에 붙을 때 `DASHBOARD_API_BASE_URL=http://10.0.2.2:8765` 사용 가능 여부 확인
- Android에서 HTTP cleartext 오류가 실제로 발생하기 전까지 `network_security_config.xml`은 추가하지 않음

Android 실기기 테스트 조건:

- 휴대폰 개발자 옵션 활성화
- USB debugging 활성화
- USB 연결 후 `adb devices` 또는 `flutter devices`에서 인식 확인
- API mode 테스트 시 `127.0.0.1` 사용 금지
- 같은 네트워크의 PC LAN IP 또는 HTTPS URL 사용
- PC LAN IP를 쓸 때 Windows 방화벽과 같은 네트워크 여부 확인

Android 연결 주소 기준:

- Windows desktop 실행: `http://127.0.0.1:8765`
- Android emulator: `http://10.0.2.2:8765`
- Android real device: 같은 네트워크의 PC LAN IP 또는 HTTPS URL
- Android real device에서는 `127.0.0.1`을 사용하지 않습니다.

APK 빌드 확인:

```bash
flutter build apk --debug
```

## Android 네트워크 보안 정책

운영 권장 구조:

```text
Flutter 앱 -> HTTPS reverse proxy(443) -> localhost 또는 내부 8765 dashboard_api
```

- 운영 배포에서는 `DASHBOARD_API_BASE_URL=https://your-domain.example` 형태를 권장합니다.
- `dashboard_api`의 8765 포트를 외부에 직접 공개하지 말고, 서버 내부 또는 제한된 접근으로 둡니다.
- AndroidManifest에는 `android.permission.INTERNET`만 필요합니다.
- `android:usesCleartextTraffic="true"`를 전역으로 켜지 않습니다.

임시 테스트로 `http://server:8765`에 직접 연결할 수는 있지만 운영 권장 방식이 아닙니다. 이 경우 Android cleartext 정책 때문에 실패할 수 있으며, 필요하면 테스트 전용 `network_security_config`로 특정 테스트 도메인/IP만 허용하는 방식으로 제한해야 합니다. 이 저장소에는 기본적으로 cleartext 허용 설정을 추가하지 않습니다.

## Android API mode 확인

실제 Android 기기에서 Oracle dashboard API에 연결하기 전 확인 항목:

- `android.permission.INTERNET` 권한이 AndroidManifest에 있어야 합니다.
- `DASHBOARD_API_BASE_URL`은 Oracle dashboard_api 주소만 사용합니다.
- `DASHBOARD_READ_TOKEN`은 서버 `.env`의 read-only token과 동일해야 합니다.
- Oracle 보안 목록/firewall에서 포트 `8765` 접근이 가능해야 합니다.
- 먼저 브라우저나 curl로 `/health`를 확인한 뒤 Flutter API mode를 실행합니다.
- API mode에서 서버 미실행, URL 오입력, token 오류, 401/403/404, JSON 파싱 실패가 발생하면 앱은 mock snapshot으로 fallback하고 화면에 데이터 소스/경고를 표시합니다.

주의: 기본 실행은 계속 mock이며, API 호출은 `SNAPSHOT_SOURCE=api`일 때만 수행됩니다.

## 장애 처리

- API 모드에서 서버 주소가 비어 있으면 mock으로 fallback합니다.
- API 호출 실패, timeout, HTTP 오류가 발생해도 앱은 크래시하지 않고 mock으로 fallback합니다.
- API 호출은 `SNAPSHOT_SOURCE=api`일 때만 수행됩니다.

## 보안 원칙

- `DASHBOARD_READ_TOKEN`을 코드에 하드코딩하지 않습니다.
- KIS key, 계좌번호, broker/order/risk 객체를 앱에 넣지 않습니다.
- 앱은 `/snapshot/account` read-only snapshot만 표시하도록 설계합니다.

## 개발 검증

```bash
flutter analyze
flutter test
```













