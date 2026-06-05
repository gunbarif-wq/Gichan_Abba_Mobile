enum SnapshotSource { mock, api }

class AppConfig {
  static const String mockSnapshotAsset =
      'assets/mock/paper_account_snapshot.json';
  static const bool readOnlyDashboard = true;
  static const bool orderControlsEnabled = false;

  static const String snapshotSourceName = 'api';
  static SnapshotSource get snapshotSource => SnapshotSource.api;

  static const String apiBaseUrl = 'http://168.110.107.27:8765';
  static const String apiReadToken = 'gichan-local-dev-8765';
}
