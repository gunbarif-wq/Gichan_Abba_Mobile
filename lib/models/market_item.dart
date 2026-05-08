class MarketItem {
  MarketItem({
    required this.id,
    required this.label,
    required this.code,
    required this.unit,
    required this.value,
    required this.updatedAt,
    required this.isMock,
    this.previousValue,
  });

  final String id;
  final String label;
  final String code;
  final String unit;
  final double value;
  final double? previousValue;
  final DateTime updatedAt;
  final bool isMock;

  double get change => previousValue == null ? 0 : value - previousValue!;
  double get changePct => previousValue == null || previousValue == 0
      ? 0
      : (change / previousValue!) * 100;
}
