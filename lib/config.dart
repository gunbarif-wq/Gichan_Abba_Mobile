enum SnapshotSource { mock, api }

class AppConfig {
  static const String mockSnapshotAsset =
      'assets/mock/paper_account_snapshot.json';
  static const bool readOnlyDashboard = true;
  static const bool orderControlsEnabled = false;

  /// 기본값: mock(asset JSON). 빌드 시 --dart-define=SNAPSHOT_SOURCE=api 로만 API 모드 활성화.
  static const String snapshotSourceName = String.fromEnvironment(
    'SNAPSHOT_SOURCE',
    defaultValue: 'mock',
  );

  static SnapshotSource get snapshotSource =>
      snapshotSourceName.toLowerCase() == 'api'
      ? SnapshotSource.api
      : SnapshotSource.mock;

  /// API 모드 전용. 예: --dart-define=DASHBOARD_API_BASE_URL=http://server:8765
  static const String apiBaseUrl = String.fromEnvironment(
    'DASHBOARD_API_BASE_URL',
    defaultValue: '',
  );

  /// dashboard_api read-only token. 실제 값은 코드에 하드코딩하지 않고 dart-define으로만 주입.
  /// 예: --dart-define=DASHBOARD_READ_TOKEN=...
  static const String apiReadToken = String.fromEnvironment(
    'DASHBOARD_READ_TOKEN',
    defaultValue: '',
  );
}
