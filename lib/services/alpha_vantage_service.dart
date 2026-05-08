class ApiPoint {
  const ApiPoint({required this.value, required this.date, required this.unit});

  final double value;
  final DateTime date;
  final String unit;
}

class AlphaVantageService {
  const AlphaVantageService();

  bool get isConfigured => false;

  Future<ApiPoint?> fetchUsdKrw() async => null;
  Future<ApiPoint?> fetchWti({String interval = 'daily'}) async => null;
  Future<ApiPoint?> fetchBrent({String interval = 'daily'}) async => null;
  Future<ApiPoint?> fetchCopper({String interval = 'monthly'}) async => null;
  Future<ApiPoint?> fetchGoldSpot() async => null;
}
