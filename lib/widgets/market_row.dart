import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/market_item.dart';

class MarketRow extends StatelessWidget {
  const MarketRow({super.key, required this.item});

  final MarketItem item;

  @override
  Widget build(BuildContext context) {
    final timeText = DateFormat('HH:mm:ss').format(item.updatedAt);
    final valueText = _formatValue(item.value);
    final changeText = _formatChange(item.change, item.changePct);
    final changeColor = item.change >= 0
        ? const Color(0xFFE86B63)
        : const Color(0xFF4B87E5);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF22272E),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      item.label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (item.isMock)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3A4049),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFF555C66)),
                        ),
                        child: const Text(
                          'Derived',
                          style: TextStyle(
                            color: Color(0xFFB8BDC6),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.access_time,
                      size: 14,
                      color: Color(0xFF76E389),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$timeText  |  ${item.code}',
                      style: const TextStyle(
                        color: Color(0xFFB1B7C0),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B4754),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  valueText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                changeText,
                style: TextStyle(
                  color: changeColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatValue(double value) {
    final formatter = NumberFormat('#,##0.00');
    return formatter.format(value);
  }

  String _formatChange(double change, double pct) {
    final formatter = NumberFormat('+#,##0.00;-#,##0.00');
    final pctFormatter = NumberFormat('+#0.00;-#0.00');
    return '${formatter.format(change)} (${pctFormatter.format(pct)}%)';
  }
}
