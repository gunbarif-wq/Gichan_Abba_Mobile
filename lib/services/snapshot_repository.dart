import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config.dart';
import '../models/account_snapshot.dart';

enum SnapshotLoadSource { mock, api, apiFallbackMock }

class SnapshotLoadResult {
  SnapshotLoadResult({
    required this.snapshot,
    required this.source,
    this.warning,
    this.apiStatusCode,
    this.apiError,
    this.repositoryType = 'SnapshotRepository',
    this.requestedUrl,
    DateTime? fetchedAt,
  }) : fetchedAt = fetchedAt ?? DateTime.now();

  final AccountSnapshot snapshot;
  final SnapshotLoadSource source;
  final String? warning;
  final int? apiStatusCode;
  final String? apiError;
  final String repositoryType;
  final String? requestedUrl;
  final DateTime fetchedAt;

  bool get usedApi => source == SnapshotLoadSource.api;
  bool get usedFallback => source == SnapshotLoadSource.apiFallbackMock;

  String get sourceLabel => switch (source) {
    SnapshotLoadSource.mock => 'mock',
    SnapshotLoadSource.api => 'api',
    SnapshotLoadSource.apiFallbackMock => 'api -> mock fallback',
  };

  String get configSnapshotSource => AppConfig.snapshotSourceName;
  String get configApiBaseUrl => AppConfig.apiBaseUrl;
  bool get tokenPresent => AppConfig.apiReadToken.isNotEmpty;
}

class SnapshotRepository {
  const SnapshotRepository();

  /// 기존 호출 호환용: snapshot만 반환한다.
  Future<AccountSnapshot> load() async => (await loadWithMetadata()).snapshot;

  /// AppConfig.snapshotSource 에 따라 mock 또는 API에서 스냅샷을 로드한다.
  /// API 모드에서 오류 발생 시 mock으로 자동 fallback하고 경고 metadata를 함께 반환한다.
  Future<SnapshotLoadResult> loadWithMetadata() async {
    _logConfig();
    if (AppConfig.snapshotSource == SnapshotSource.api) {
      return _loadFromApi();
    }
    return SnapshotLoadResult(
      snapshot: await _loadMock(),
      source: SnapshotLoadSource.mock,
      fetchedAt: DateTime.now(),
    );
  }

  void _logConfig() {
    debugPrint(
      '[SnapshotRepository] config '
      'snapshotSource=${AppConfig.snapshotSourceName} '
      'apiBaseUrl=${AppConfig.apiBaseUrl.isEmpty ? "(empty)" : AppConfig.apiBaseUrl} '
      'token_present=${AppConfig.apiReadToken.isNotEmpty} '
      'repository_type=SnapshotRepository',
    );
  }

  Future<AccountSnapshot> _loadMock() async {
    final source = await rootBundle.loadString(AppConfig.mockSnapshotAsset);
    return AccountSnapshot.fromJsonString(source);
  }

  Future<SnapshotLoadResult> _loadFromApi() async {
    try {
      if (AppConfig.apiBaseUrl.isEmpty) {
        debugPrint(
          '[SnapshotRepository] api_skipped reason=empty_base_url '
          'status_code=none',
        );
        return SnapshotLoadResult(
          snapshot: await _loadMock(),
          source: SnapshotLoadSource.apiFallbackMock,
          warning: 'API mode requested but DASHBOARD_API_BASE_URL is empty.',
          apiError: 'empty_base_url',
          fetchedAt: DateTime.now(),
        );
      }
      final uri = Uri.parse('${AppConfig.apiBaseUrl}/snapshot/account');
      final headers = <String, String>{};
      if (AppConfig.apiReadToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer ${AppConfig.apiReadToken}';
      }
      final response = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 10));
      debugPrint(
        '[SnapshotRepository] api_response '
        'url=$uri status_code=${response.statusCode}',
      );
      if (response.statusCode == 200) {
        return SnapshotLoadResult(
          snapshot: AccountSnapshot.fromJsonString(response.body),
          source: SnapshotLoadSource.api,
          apiStatusCode: response.statusCode,
          requestedUrl: uri.toString(),
          fetchedAt: DateTime.now(),
        );
      }
      return SnapshotLoadResult(
        snapshot: await _loadMock(),
        source: SnapshotLoadSource.apiFallbackMock,
        warning:
            'API request failed with HTTP ${response.statusCode}. Showing mock fallback.',
        apiStatusCode: response.statusCode,
        apiError: 'http_${response.statusCode}',
        requestedUrl: uri.toString(),
        fetchedAt: DateTime.now(),
      );
    } catch (error) {
      debugPrint('[SnapshotRepository] api_error error=$error');
      return SnapshotLoadResult(
        snapshot: await _loadMock(),
        source: SnapshotLoadSource.apiFallbackMock,
        warning: 'API request failed: $error. Showing mock snapshot fallback.',
        apiError: error.toString(),
        requestedUrl: AppConfig.apiBaseUrl.isEmpty
            ? null
            : '${AppConfig.apiBaseUrl}/snapshot/account',
        fetchedAt: DateTime.now(),
      );
    }
  }

  @Deprecated('load() 또는 loadWithMetadata() 를 사용하세요')
  Future<AccountSnapshot> loadMockSnapshot() => _loadMock();
}
