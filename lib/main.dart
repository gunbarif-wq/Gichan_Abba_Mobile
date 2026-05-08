import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'config.dart';
import 'models/account_snapshot.dart';
import 'services/snapshot_repository.dart';

void main() => runApp(const GichanMockDashboardApp());

class GichanMockDashboardApp extends StatelessWidget {
  const GichanMockDashboardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Gichan Abba System',
      builder: (context, child) {
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(textScaler: const TextScaler.linear(1.0)),
          child: child ?? const SizedBox.shrink(),
        );
      },
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.blue,
          brightness: Brightness.dark,
        ),
        fontFamily: 'Roboto',
      ),
      home: const DashboardPage(),
    );
  }
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final SnapshotRepository _repository = const SnapshotRepository();
  SnapshotLoadResult? _result;
  Timer? _refreshTimer;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _load();
    if (AppConfig.snapshotSource == SnapshotSource.api) {
      _refreshTimer = Timer.periodic(
        const Duration(seconds: 5),
        (_) => _load(),
      );
    }
  }

  Future<void> _load() async {
    if (_isRefreshing) return;
    _isRefreshing = true;
    try {
      final result = await _repository.loadWithMetadata();
      if (!mounted) return;
      setState(() => _result = result);
    } finally {
      _isRefreshing = false;
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _result != null
            ? DashboardContent(result: _result!)
            : const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class DashboardContent extends StatefulWidget {
  const DashboardContent({super.key, required this.result});

  final SnapshotLoadResult result;

  @override
  State<DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<DashboardContent> {
  bool showAllWatchlist = false;
  bool showAllTrades = false;

  SnapshotLoadResult get result => widget.result;
  AccountSnapshot get snapshot => result.snapshot;

  @override
  Widget build(BuildContext context) {
    final account = snapshot.account;
    final positions = snapshot.positions;
    final refDate = DateTime.tryParse(snapshot.generatedAt) ?? DateTime.now();
    final recentDates = _lastNTradingDayDates(refDate, 5);
    final closedTrades = snapshot.recentTrades.where((trade) {
      if (trade.sellAmount <= 0 || trade.buyAmount <= 0) return false;
      final parsed = DateTime.tryParse(trade.time);
      if (parsed == null) return false;
      return recentDates.contains(DateFormat('yyyy-MM-dd').format(parsed));
    }).toList();
    final visibleWatchlist = showAllWatchlist
        ? snapshot.watchlist
        : snapshot.watchlist.take(5).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
      children: [
        HeaderSection(result: result),
        const SizedBox(height: 11),
        AccountInfoCard(account: account, dailyPnls: snapshot.dailyPnls),
        const SizedBox(height: 10),
        PositionsTableCard(positions: positions),
        const SizedBox(height: 10),
        WatchlistTableCard(
          items: visibleWatchlist,
          totalCount: snapshot.watchlist.length,
          expanded: showAllWatchlist,
          onToggle: snapshot.watchlist.length > 5
              ? () => setState(() => showAllWatchlist = !showAllWatchlist)
              : null,
        ),
        const SizedBox(height: 10),
        RecentClosedTradesCard(
          trades: showAllTrades ? closedTrades : closedTrades.take(5).toList(),
          totalCount: closedTrades.length,
          expanded: showAllTrades,
          onToggle: closedTrades.length > 5
              ? () => setState(() => showAllTrades = !showAllTrades)
              : null,
        ),
      ],
    );
  }
}

class HeaderSection extends StatelessWidget {
  const HeaderSection({super.key, required this.result});

  final SnapshotLoadResult result;

  @override
  Widget build(BuildContext context) {
    final snapshot = result.snapshot;
    final status = snapshot.operationStatus;
    final isRealMode = status.brokerMode.toLowerCase() == 'real';
    final modeLabel = isRealMode ? 'REAL MODE' : 'PAPER MODE';
    final kisLabel = status.kisApiBlocked ? 'KIS API BLOCKED' : 'KIS CONNECTED';
    final orderLabel = isRealMode
        ? 'APP ORDER DISABLED'
        : 'REAL ORDER DISABLED';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Gichan Abba System',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.7,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          '운영 대시보드 (Read-Only)',
          style: TextStyle(color: AppColors.textMuted, fontSize: 13),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: StatusPill(
                label: modeLabel,
                icon: Icons.account_balance_wallet_outlined,
                color: AppColors.blue,
              ),
            ),
            SizedBox(width: 4),
            Expanded(
              child: StatusPill(
                label: snapshot.readOnly ? 'READ-ONLY' : 'READ-WRITE',
                icon: Icons.lock,
                color: AppColors.green,
              ),
            ),
            SizedBox(width: 4),
            Expanded(
              child: StatusPill(
                label: kisLabel,
                icon: Icons.shield,
                color: status.kisApiBlocked ? AppColors.red : AppColors.green,
              ),
            ),
            SizedBox(width: 4),
            Expanded(
              child: StatusPill(
                label: orderLabel,
                icon: Icons.settings_backup_restore,
                color: AppColors.amber,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: HeaderMeta(
                icon: Icons.schedule,
                text:
                    '마지막 조회: ${DateFormat('HH:mm:ss').format(result.fetchedAt)}',
              ),
            ),
            const SizedBox(width: 8),
            HeaderMeta(
              icon: Icons.sync,
              text: '데이터 소스: ${sourceText(result.sourceLabel)}',
              trailing: Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: result.usedApi ? AppColors.green : AppColors.amber,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
        if (result.warning != null) ...[
          const SizedBox(height: 9),
          WarningBox(message: result.warning!),
        ],
      ],
    );
  }
}

class AccountInfoCard extends StatelessWidget {
  const AccountInfoCard({
    super.key,
    required this.account,
    required this.dailyPnls,
  });

  final AccountSummary account;
  final List<DailyPnlSnapshot> dailyPnls;

  @override
  Widget build(BuildContext context) {
    return DashboardPanel(
      title: '계좌정보',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            children: [
              Expanded(
                child: StatTile(
                  icon: Icons.trending_up,
                  label: '총수익률',
                  value: signedPct(account.totalReturnPct),
                  tone: account.totalReturnPct,
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: StatTile(
                  icon: Icons.show_chart,
                  label: '금일수익률',
                  value: signedPct(account.todayReturnPct),
                  tone: account.todayReturnPct,
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: StatTile(
                  icon: Icons.pie_chart,
                  label: '승률',
                  value: '${account.winRatePct.toStringAsFixed(1)}%',
                  inlineSubValue: account.winCount + account.lossCount > 0
                      ? '(${account.winCount}승 / ${account.lossCount}패)'
                      : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              Expanded(
                child: StatTile(
                  icon: Icons.bar_chart,
                  label: '누적순익',
                  value: signedWon(account.cumulativeNetPnl),
                  tone: account.cumulativeNetPnl,
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: StatTile(
                  icon: Icons.show_chart,
                  label: '금일수익',
                  value: todayReturnText(account),
                  tone: account.todayReturnPct,
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: StatTile(
                  icon: Icons.account_balance_wallet,
                  label: '평가금액',
                  value: won(account.totalAsset),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '손익 그래프',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 12.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          ProfitChart(items: dailyPnls),
        ],
      ),
    );
  }
}

class ProfitChart extends StatelessWidget {
  const ProfitChart({super.key, required this.items});

  final List<DailyPnlSnapshot> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox(
        height: 40,
        child: Center(
          child: Text(
            '표시할 거래일 손익이 없습니다.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 11),
          ),
        ),
      );
    }
    final chartItems = items.length > 7
        ? items.sublist(items.length - 7)
        : items;
    final maxAbs = chartItems
        .map((e) => e.pnl.abs())
        .fold<double>(1, (a, b) => a > b ? a : b);
    return SizedBox(
      height: 121,
      child: Stack(
        children: [
          Positioned.fill(
            left: 38,
            right: 6,
            top: 14,
            bottom: 25,
            child: CustomPaint(painter: ChartGridPainter()),
          ),
          Positioned(
            left: 0,
            top: 14,
            bottom: 27,
            width: 36,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('200K', style: axisLabelStyle),
                Text('100K', style: axisLabelStyle),
                Text('0', style: axisLabelStyle),
                Text('-100K', style: axisLabelStyle),
                Text('-200K', style: axisLabelStyle),
              ],
            ),
          ),
          Positioned.fill(
            left: 41,
            right: 4,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: chartItems.map((bar) {
                final height = 6 + (bar.pnl.abs() / maxAbs * 36);
                final isProfit = bar.pnl >= 0;
                return Expanded(
                  child: Column(
                    children: [
                      SizedBox(
                        height: 13,
                        child: Text(
                          isProfit ? signedNumber(bar.pnl) : '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.red,
                            fontSize: 7,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 72,
                        child: Column(
                          children: [
                            Expanded(
                              child: Align(
                                alignment: Alignment.bottomCenter,
                                child: isProfit
                                    ? ChartBar(
                                        height: height,
                                        color: AppColors.red,
                                      )
                                    : const SizedBox.shrink(),
                              ),
                            ),
                            Container(
                              height: 1,
                              color: AppColors.border.withValues(alpha: 0.8),
                            ),
                            Expanded(
                              child: Align(
                                alignment: Alignment.topCenter,
                                child: !isProfit
                                    ? ChartBar(
                                        height: height,
                                        color: AppColors.blue,
                                      )
                                    : const SizedBox.shrink(),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 15,
                        child: Text(
                          !isProfit ? signedNumber(bar.pnl) : '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.blue,
                            fontSize: 7,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 18,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            chartDateLabel(bar),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class ChartBar extends StatelessWidget {
  const ChartBar({super.key, required this.height, required this.color});

  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.32), blurRadius: 9),
        ],
      ),
    );
  }
}

class ChartGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = AppColors.border.withValues(alpha: 0.38)
      ..strokeWidth = 1;
    for (final ratio in [0.0, 0.25, 0.5, 0.75, 1.0]) {
      final y = size.height * ratio;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class PositionsTableCard extends StatelessWidget {
  const PositionsTableCard({super.key, required this.positions});

  final List<PositionSnapshot> positions;

  @override
  Widget build(BuildContext context) {
    return DashboardPanel(
      title: '보유종목',

      child: positions.isEmpty
          ? const EmptyState(text: '미청산 보유 종목이 없습니다.')
          : Column(
              children: [
                const DataHeader(
                  cells: ['종목명', '수량', '평균단가', '현재가', '평가손익', '수익률'],
                  flexes: [22, 8, 13, 13, 15, 10],
                  alignments: [
                    Alignment.center,
                    Alignment.center,
                    Alignment.center,
                    Alignment.center,
                    Alignment.center,
                    Alignment.center,
                  ],
                ),
                ...positions.map(
                  (p) => DataRowLine(
                    flexes: const [22, 8, 13, 13, 15, 10],
                    alignments: const [
                      Alignment.center,
                      Alignment.center,
                      Alignment.center,
                      Alignment.center,
                      Alignment.center,
                      Alignment.center,
                    ],
                    cells: [
                      NameText(p.name, p.symbol),
                      PlainText('${p.quantity}'),
                      PlainText(price(p.entryPrice)),
                      PlainText(price(p.currentPrice)),
                      MoneyText(p.unrealizedPnl),
                      PercentText(p.unrealizedPnlPct),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class WatchlistTableCard extends StatelessWidget {
  const WatchlistTableCard({
    super.key,
    required this.items,
    required this.totalCount,
    required this.expanded,
    this.onToggle,
  });

  final List<WatchItem> items;
  final int totalCount;
  final bool expanded;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    return DashboardPanel(
      title: '감시종목',
      trailingWidget: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$totalCount개', style: panelTrailingStyle),
              SizedBox(width: 4),
              Icon(
                expanded ? Icons.keyboard_arrow_up : Icons.chevron_right,
                color: AppColors.textSoft,
                size: 19,
              ),
            ],
          ),
        ),
      ),
      child: items.isEmpty
          ? const EmptyState(text: '현재 감시종목이 없습니다.')
          : Column(
              children: [
                const DataHeader(
                  cells: ['종목명', '현재가', '등락률', '감시 사유'],
                  flexes: [28, 16, 12, 32],
                  alignments: [
                    Alignment.center,
                    Alignment.center,
                    Alignment.center,
                    Alignment.center,
                  ],
                ),
                ...items.map(
                  (item) {
                    final sellBadge = item.isSellWatch
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            margin: const EdgeInsets.only(left: 4),
                            decoration: BoxDecoration(
                              color: Color(0xFFFF6B35).withOpacity(0.18),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: const Color(0xFFFF6B35), width: 0.7),
                            ),
                            child: const Text('매도감시', style: TextStyle(fontSize: 9, color: Color(0xFFFF6B35))),
                          )
                        : const SizedBox.shrink();
                    final nameCell = Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(child: NameText(item.name, item.symbol)),
                        sellBadge,
                      ],
                    );
                    final _baseReason = item.watchReasonText.isNotEmpty
                        ? item.watchReasonText
                        : (item.isSellWatch ? '매도감시' : item.stageStatus);
                    final reasonText = item.isSellWatch && item.pnlPct != 0.0
                        ? '$_baseReason (${item.pnlPct >= 0 ? "+" : ""}${item.pnlPct.toStringAsFixed(2)}%)'
                        : _baseReason;
                    return Container(
                      color: item.isSellWatch ? Color(0xFFFF6B35).withOpacity(0.04) : null,
                      child: DataRowLine(
                        flexes: const [28, 16, 12, 32],
                        alignments: const [
                          Alignment.center,
                          Alignment.center,
                          Alignment.center,
                          Alignment.center,
                        ],
                        cells: [
                          nameCell,
                          PlainText(price(item.currentPrice)),
                          item.isSellWatch
                              ? PercentText(item.pnlPct)
                              : PercentText(item.changePct),
                          Padding(
                            padding: const EdgeInsets.only(left: 10),
                            child: PlainText(reasonText, maxLines: 2),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
    );
  }
}

class RecentClosedTradesCard extends StatelessWidget {
  const RecentClosedTradesCard({
    super.key,
    required this.trades,
    required this.totalCount,
    required this.expanded,
    this.onToggle,
  });

  final List<TradeSnapshot> trades;
  final int totalCount;
  final bool expanded;
  final VoidCallback? onToggle;

  static const _flexes = [22, 7, 14, 14, 15, 10];
  static const _aligns = [
    Alignment.center,
    Alignment.center,
    Alignment.center,
    Alignment.center,
    Alignment.center,
    Alignment.center,
  ];

  @override
  Widget build(BuildContext context) {
    return DashboardPanel(
      title: '체결내역',
      trailingWidget: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$totalCount개', style: panelTrailingStyle),
              SizedBox(width: 4),
              Icon(
                expanded ? Icons.keyboard_arrow_up : Icons.chevron_right,
                color: AppColors.textSoft,
                size: 19,
              ),
            ],
          ),
        ),
      ),
      child: trades.isEmpty
          ? const EmptyState(text: '청산 완료 체결이 없습니다.')
          : Column(
              children: [
                const DataHeader(
                  cells: ['종목명', '주수', '매수금액', '매도금액', '실현손익', '수익률'],
                  flexes: _flexes,
                  alignments: _aligns,
                ),
                ...trades.map(
                  (trade) => DataRowLine(
                    flexes: _flexes,
                    alignments: _aligns,
                    cells: [
                      NameText(trade.name, trade.symbol),
                      PlainText('${trade.quantity}'),
                      PlainText(price(trade.buyAmount)),
                      PlainText(price(trade.sellAmount)),
                      MoneyText(trade.realizedPnl),
                      PercentText(trade.realizedPnlPct),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class DashboardPanel extends StatelessWidget {
  const DashboardPanel({
    super.key,
    required this.title,
    required this.child,
    this.trailing,
    this.trailingWidget,
  });

  final String title;
  final Widget child;
  final String? trailing;
  final Widget? trailingWidget;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: AppColors.border),
        boxShadow: const [BoxShadow(color: Color(0x55000000), blurRadius: 18)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
              ),
              ?trailingWidget,
              if (trailing != null) Text(trailing!, style: panelTrailingStyle),
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color),
      ),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 10),
              const SizedBox(width: 3),
              Text(
                label,
                maxLines: 1,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: color,
                  fontSize: 8.8,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HeaderMeta extends StatelessWidget {
  const HeaderMeta({super.key, this.icon, required this.text, this.trailing});

  final IconData? icon;
  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, color: AppColors.textMuted, size: 12),
          SizedBox(width: 4),
        ],
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 10.5),
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 6), trailing!],
      ],
    );
  }
}

class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.subValue,
    this.inlineSubValue,
    this.tone,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? subValue;
  final String? inlineSubValue;
  final double? tone;

  @override
  Widget build(BuildContext context) {
    final color = valueColor(tone);
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.tile,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Icon(icon, color: AppColors.blue, size: 12),
              const SizedBox(width: 3),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSoft,
                    fontSize: 9.6,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.center,
            child: RichText(
              maxLines: 1,
              textAlign: TextAlign.center,
              text: TextSpan(
                text: value,
                style: TextStyle(
                  color: color,
                  fontSize: 12.2,
                  fontWeight: FontWeight.w900,
                ),
                children: [
                  if (inlineSubValue != null)
                    TextSpan(
                      text: ' $inlineSubValue',
                      style: TextStyle(
                        color: color,
                        fontSize: 7.8,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (subValue != null) ...[
            const SizedBox(height: 1),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.center,
              child: Text(
                subValue!,
                maxLines: 1,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: color,
                  fontSize: 7.8,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class DataHeader extends StatelessWidget {
  const DataHeader({
    super.key,
    required this.cells,
    this.flexes,
    this.alignments,
  });

  final List<String> cells;
  final List<int>? flexes;
  final List<Alignment>? alignments;

  @override
  Widget build(BuildContext context) {
    return DataRowLine(
      isHeader: true,
      flexes: flexes,
      alignments: alignments,
      cells: cells
          .map(
            (cell) => Text(
              cell,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w700,
                fontSize: 9.8,
              ),
            ),
          )
          .toList(),
    );
  }
}

class DataRowLine extends StatelessWidget {
  const DataRowLine({
    super.key,
    required this.cells,
    this.isHeader = false,
    this.flexes,
    this.alignments,
  });

  final List<Widget> cells;
  final bool isHeader;
  final List<int>? flexes;
  final List<Alignment>? alignments;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: isHeader ? 5 : 6),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.border.withValues(alpha: 0.45)),
        ),
      ),
      child: Row(
        children: [
          for (var i = 0; i < cells.length; i++)
            Expanded(
              flex: flexes != null && i < flexes!.length ? flexes![i] : 1,
              child: Align(
                alignment: alignments != null && i < alignments!.length
                    ? alignments![i]
                    : Alignment.center,
                child: DefaultTextStyle(
                  style: const TextStyle(
                    color: AppColors.textMain,
                    fontSize: 10.5,
                  ),
                  child: cells[i],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class NameText extends StatelessWidget {
  const NameText(this.name, this.symbol, {super.key});

  final String name;
  final String symbol;

  @override
  Widget build(BuildContext context) {
    return Text(
      name.isEmpty ? '-' : name,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 10.8,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class PlainText extends StatelessWidget {
  const PlainText(this.text, {super.key, this.maxLines = 1});

  final String text;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(color: AppColors.textMain, fontSize: 11),
    );
  }
}

class MoneyText extends StatelessWidget {
  const MoneyText(this.value, {super.key});

  final double value;

  @override
  Widget build(BuildContext context) => Text(
    signedNumber(value),
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: TextStyle(
      color: valueColor(value),
      fontWeight: FontWeight.w800,
      fontSize: 11,
    ),
  );
}

class PercentText extends StatelessWidget {
  const PercentText(this.value, {super.key});

  final double value;

  @override
  Widget build(BuildContext context) => Text(
    signedPct(value),
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: TextStyle(
      color: valueColor(value),
      fontWeight: FontWeight.w800,
      fontSize: 11,
    ),
  );
}

class StageBadge extends StatelessWidget {
  const StageBadge(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final warning =
        text.contains('주의') || text.toLowerCase().contains('pending');
    final color = warning ? AppColors.amber : AppColors.blue;
    return Align(
      alignment: Alignment.center,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color),
          color: color.withValues(alpha: 0.08),
        ),
        child: Text(
          text.isEmpty ? '관심' : text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w800,
            fontSize: 10.5,
          ),
        ),
      ),
    );
  }
}

class WarningBox extends StatelessWidget {
  const WarningBox({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.amber.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.amber),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: AppColors.amber,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: const TextStyle(color: AppColors.textMuted));
}

class AppColors {
  static const background = Color(0xFF00111B);
  static const panel = Color(0xCC031D2B);
  static const tile = Color(0xAA061A27);
  static const border = Color(0xFF1E4A64);
  static const textMain = Color(0xFFE5EDF5);
  static const textMuted = Color(0xFF96A6B8);
  static const textSoft = Color(0xFFC4CED8);
  static const green = Color(0xFF00E064);
  static const red = Color(0xFFFF2F3A);
  static const blue = Color(0xFF2E8EFF);
  static const amber = Color(0xFFFFB000);
}

const panelTrailingStyle = TextStyle(
  color: AppColors.textSoft,
  fontSize: 13,
  fontWeight: FontWeight.w700,
);
const axisLabelStyle = TextStyle(
  color: AppColors.textMuted,
  fontSize: 7,
  fontWeight: FontWeight.w500,
);

final wonFormat = NumberFormat('#,##0');

Color valueColor(double? value) {
  if (value == null || value == 0) return AppColors.textMain;
  return value > 0 ? AppColors.red : AppColors.blue;
}

String sourceText(String source) {
  if (source == 'api') return 'API';
  if (source == 'mock') return 'mock';
  return source;
}

String won(double value) => '${wonFormat.format(value.round())}원';
String price(double value) => wonFormat.format(value.round());
String signedWon(double value) => '${value >= 0 ? '+' : ''}${won(value)}';
String signedNumber(double value) =>
    '${value >= 0 ? '+' : ''}${wonFormat.format(value.round())}';
String signedPct(double value) =>
    '${value >= 0 ? '+' : ''}${value.toStringAsFixed(2)}%';

String chartDateLabel(DailyPnlSnapshot item) {
  final parsed = DateTime.tryParse(item.date);
  if (parsed != null) return DateFormat('MM/dd').format(parsed);
  final compact = RegExp(r'^(\d{4})(\d{2})(\d{2})$').firstMatch(item.date);
  if (compact != null) return '${compact.group(2)}/${compact.group(3)}';
  return item.date.isNotEmpty ? item.date : item.day;
}

String todayReturnText(AccountSummary account) {
  if (account.todayReturnPct == 0 || account.totalAsset == 0) return '+0원';
  return signedWon(account.totalAsset * account.todayReturnPct / 100);
}

String formatFullTime(String value) {
  final parsed = DateTime.tryParse(value);
  if (parsed == null) return value.isEmpty ? '-' : value;
  return DateFormat('yyyy-MM-dd HH:mm:ss').format(parsed);
}

String formatShortTime(String value) {
  final parsed = DateTime.tryParse(value);
  if (parsed == null) return value.isEmpty ? '-' : value;
  return DateFormat('MM-dd HH:mm:ss').format(parsed);
}

String formatTradingTime(String value) {
  final parsed = DateTime.tryParse(value);
  if (parsed == null) return value.isEmpty ? '-' : value;
  return DateFormat('M/d HH:mm').format(parsed);
}

Set<String> _lastNTradingDayDates(DateTime ref, int n) {
  final dates = <String>{};
  var cursor = DateTime(ref.year, ref.month, ref.day);
  while (dates.length < n) {
    if (cursor.weekday != DateTime.saturday &&
        cursor.weekday != DateTime.sunday) {
      dates.add(DateFormat('yyyy-MM-dd').format(cursor));
    }
    cursor = cursor.subtract(const Duration(days: 1));
  }
  return dates;
}
