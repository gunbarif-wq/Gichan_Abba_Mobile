import 'dart:convert';

class AccountSnapshot {
  AccountSnapshot({
    required this.generatedAt,
    required this.readOnly,
    required this.account,
    required this.positions,
    required this.watchlist,
    required this.recentTrades,
    required this.dailyPnls,
    required this.operationStatus,
    required this.costPolicy,
  });

  final String generatedAt;
  final bool readOnly;
  final AccountSummary account;
  final List<PositionSnapshot> positions;
  final List<WatchItem> watchlist;
  final List<TradeSnapshot> recentTrades;
  final List<DailyPnlSnapshot> dailyPnls;
  final OperationStatus operationStatus;
  final CostPolicy costPolicy;

  factory AccountSnapshot.fromJsonString(String source) {
    return AccountSnapshot.fromJson(jsonDecode(source) as Map<String, dynamic>);
  }

  factory AccountSnapshot.fromJson(Map<String, dynamic> json) {
    return AccountSnapshot(
      generatedAt: json['generated_at']?.toString() ?? '',
      readOnly: json['read_only'] == true,
      account: AccountSummary.fromJson(asMap(json['account'])),
      positions: asList(
        json['positions'],
      ).map((e) => PositionSnapshot.fromJson(asMap(e))).toList(),
      watchlist: asList(
        json['watchlist'],
      ).map((e) => WatchItem.fromJson(asMap(e))).toList(),
      recentTrades: asList(
        json['recent_trades'],
      ).map((e) => TradeSnapshot.fromJson(asMap(e))).toList(),
      dailyPnls: asList(
        json['daily_pnl'] ?? json['weekday_pnl'],
      ).map((e) => DailyPnlSnapshot.fromJson(asMap(e))).toList(),
      operationStatus: OperationStatus.fromJson(
        asMap(json['operation_status']),
      ),
      costPolicy: CostPolicy.fromJson(asMap(json['cost_policy'])),
    );
  }
}

class AccountSummary {
  AccountSummary({
    required this.totalAsset,
    required this.cashBalance,
    required this.holdingsMarketValue,
    required this.unrealizedPnl,
    required this.realizedPnl,
    required this.cumulativeNetPnl,
    required this.cumulativeNetPnlPct,
    required this.todayReturnPct,
    required this.totalReturnPct,
    required this.winRatePct,
    required this.winCount,
    required this.lossCount,
    required this.tradingCost,
  });

  final double totalAsset;
  final double cashBalance;
  final double holdingsMarketValue;
  final double unrealizedPnl;
  final double realizedPnl;
  final double cumulativeNetPnl;
  final double cumulativeNetPnlPct;
  final double todayReturnPct;
  final double totalReturnPct;
  final double winRatePct;
  final int winCount;
  final int lossCount;
  final double tradingCost;

  factory AccountSummary.fromJson(Map<String, dynamic> json) => AccountSummary(
    totalAsset: asDouble(json['total_asset']),
    cashBalance: asDouble(json['cash_balance'] ?? json['available_cash']),
    holdingsMarketValue: asDouble(json['holdings_market_value']),
    unrealizedPnl: asDouble(json['unrealized_pnl']),
    realizedPnl: asDouble(json['realized_pnl']),
    cumulativeNetPnl: asDouble(json['cumulative_net_pnl']),
    cumulativeNetPnlPct: asDouble(json['cumulative_net_pnl_pct']),
    todayReturnPct: asDouble(json['today_return_pct']),
    totalReturnPct: asDouble(
      json['total_return_pct'] ?? json['cumulative_net_pnl_pct'],
    ),
    winRatePct: asDouble(json['win_rate_pct']),
    winCount: asInt(json['win_count']),
    lossCount: asInt(json['loss_count']),
    tradingCost: asDouble(json['trading_cost']),
  );
}

class PositionSnapshot {
  PositionSnapshot({
    required this.symbol,
    required this.name,
    required this.quantity,
    required this.entryPrice,
    required this.currentPrice,
    required this.marketValue,
    required this.unrealizedPnl,
    required this.unrealizedPnlPct,
    required this.holdingMinutes,
    this.totalBuyAmount = 0.0,
  });

  final String symbol;
  final String name;
  final int quantity;
  final double entryPrice;
  final double currentPrice;
  final double marketValue;
  final double unrealizedPnl;
  final double unrealizedPnlPct;
  final double holdingMinutes;
  final double totalBuyAmount;

  factory PositionSnapshot.fromJson(Map<String, dynamic> json) =>
      PositionSnapshot(
        symbol: json['symbol']?.toString() ?? '',
        name: (json['display_name'] ?? json['name'] ?? '').toString(),
        quantity: asInt(json['quantity']),
        entryPrice: asDouble(json['entry_price']),
        currentPrice: asDouble(json['current_price']),
        marketValue: asDouble(json['market_value']),
        unrealizedPnl: asDouble(json['unrealized_pnl']),
        unrealizedPnlPct: asDouble(json['unrealized_pnl_pct']),
        holdingMinutes: asDouble(json['holding_minutes']),
        totalBuyAmount: asDouble(json['total_buy_amount']),
      );
}

class WatchItem {
  WatchItem({
    required this.symbol,
    required this.name,
    required this.currentPrice,
    required this.changePct,
    required this.stageStatus,
    required this.reason,
    required this.lastUpdate,
    this.displayReason = '',
    this.reasonsKo = const [],
    this.isSellWatch = false,
    this.pnlPct = 0.0,
    this.peakPnlPct = 0.0,
    this.holdingMinutes = 0.0,
    this.source = '',
  });

  final String symbol;
  final String name;
  final double currentPrice;
  final double changePct;
  final String stageStatus;
  /// Raw reason string (영어 코드, 내부용)
  final String reason;
  final String lastUpdate;
  /// 서버에서 한글화된 표시용 단일 문자열
  final String displayReason;
  /// 서버에서 한글화된 reason 코드 목록
  final List<String> reasonsKo;
  final bool isSellWatch;
  final double pnlPct;
  final double peakPnlPct;
  final double holdingMinutes;
  final String source;

  /// 화면 표시용 감시사유: 서버 display_reason → reasons_ko join → reason fallback 순
  String get watchReasonText {
    if (displayReason.isNotEmpty) return displayReason;
    if (reasonsKo.isNotEmpty) return reasonsKo.join(', ');
    return reason;
  }

  factory WatchItem.fromJson(Map<String, dynamic> json) {
    final rawReasonsKo = json['reasons_ko'];
    final List<String> reasonsKoList = rawReasonsKo is List
        ? List<String>.unmodifiable(
            rawReasonsKo.map((e) => (e ?? '').toString()).where((e) => e.isNotEmpty))
        : const <String>[];
    return WatchItem(
      symbol: json['symbol']?.toString() ?? '',
      name: (json['display_name'] ?? json['name'] ?? '').toString(),
      currentPrice: asDouble(json['current_price']),
      changePct: asDouble(json['change_pct']),
      stageStatus: (json['stage_status'] ?? '').toString(),
      reason: (json['reason'] ?? '').toString(),
      lastUpdate: (json['last_update'] ?? '').toString(),
      displayReason: (json['display_reason'] ?? '').toString(),
      reasonsKo: reasonsKoList,
      isSellWatch: json['is_sell_watch'] == true || (json['stage_status'] ?? '') == 'sell_watch' || (json['source'] ?? '') == 'holding_position',
      pnlPct: asDouble(json['pnl_pct']),
      peakPnlPct: asDouble(json['peak_pnl_pct']),
      holdingMinutes: asDouble(json['holding_minutes']),
      source: (json['source'] ?? '').toString(),
    );
  }
}

class TradeSnapshot {
  TradeSnapshot({
    required this.time,
    required this.symbol,
    required this.name,
    required this.quantity,
    required this.buyAmount,
    required this.sellAmount,
    required this.realizedPnl,
    required this.realizedPnlPct,
    required this.tradingCost,
    this.side = '',
  });

  final String time;
  final String symbol;
  final String name;
  final int quantity;
  final double buyAmount;
  final double sellAmount;
  final double realizedPnl;
  final double realizedPnlPct;
  final double tradingCost;
  final String side; // 'buy' | 'sell' | ''

  bool get isBuyOnly => buyAmount > 0 && sellAmount <= 0;
  bool get isSellOnly => sellAmount > 0 && buyAmount <= 0;

  factory TradeSnapshot.fromJson(Map<String, dynamic> json) => TradeSnapshot(
    time: json['time']?.toString() ?? '',
    symbol: json['symbol']?.toString() ?? '',
    name: (json['display_name'] ?? json['name'] ?? '').toString(),
    quantity: asInt(json['quantity']),
    buyAmount: asDouble(json['buy_amount']),
    sellAmount: asDouble(json['sell_amount']),
    realizedPnl: asDouble(json['realized_pnl']),
    realizedPnlPct: asDouble(json['realized_pnl_pct']),
    tradingCost: asDouble(json['trading_cost']),
    side: (json['side'] ?? '').toString(),
  );
}

class DailyPnlSnapshot {
  DailyPnlSnapshot({required this.day, required this.date, required this.pnl});

  final String day;
  final String date;
  final double pnl;

  factory DailyPnlSnapshot.fromJson(Map<String, dynamic> json) =>
      DailyPnlSnapshot(
        day: (json['day'] ?? json['weekday'] ?? '').toString(),
        date: (json['date'] ?? json['trading_date'] ?? json['day'] ?? '')
            .toString(),
        pnl: asDouble(json['pnl'] ?? json['amount']),
      );
}

class OperationStatus {
  OperationStatus({
    required this.internalPaperTrading,
    required this.realOrderEnabled,
    required this.kisApiBlocked,
    required this.brokerMode,
    required this.dryRun,
    required this.paper,
  });

  final bool internalPaperTrading;
  final bool realOrderEnabled;
  final bool kisApiBlocked;
  final String brokerMode;
  final bool dryRun;
  final bool paper;

  factory OperationStatus.fromJson(Map<String, dynamic> json) =>
      OperationStatus(
        internalPaperTrading: json['internal_paper_trading'] == true,
        realOrderEnabled: json['real_order_enabled'] == true,
        kisApiBlocked: json['kis_api_blocked'] == true,
        brokerMode: json['broker_mode']?.toString() ?? 'paper',
        dryRun: json['dry_run'] == true,
        paper: json['paper'] == true,
      );
}

class CostPolicy {
  CostPolicy({
    required this.brokerName,
    required this.brokerFeeRate,
    required this.sellTaxRate,
    required this.taxMarket,
  });

  final String brokerName;
  final double brokerFeeRate;
  final double sellTaxRate;
  final String taxMarket;

  factory CostPolicy.fromJson(Map<String, dynamic> json) => CostPolicy(
    brokerName: json['broker_name']?.toString() ?? '',
    brokerFeeRate: asDouble(json['broker_fee_rate']),
    sellTaxRate: asDouble(json['sell_tax_rate']),
    taxMarket: json['tax_market']?.toString() ?? '',
  );
}

Map<String, dynamic> asMap(Object? value) =>
    value is Map<String, dynamic> ? value : <String, dynamic>{};
List<dynamic> asList(Object? value) =>
    value is List ? value : const <dynamic>[];
double asDouble(Object? value) => value is num
    ? value.toDouble()
    : double.tryParse(value?.toString() ?? '') ?? 0;
int asInt(Object? value) =>
    value is num ? value.toInt() : int.tryParse(value?.toString() ?? '') ?? 0;
