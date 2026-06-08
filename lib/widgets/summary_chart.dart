import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';

class SummaryChart extends StatelessWidget {
  final Map<String, double> perPersonSpending; // uid → total spent
  final Map<String, String> memberNames; // uid → name
  final double totalSpent;

  const SummaryChart({
    super.key,
    required this.perPersonSpending,
    required this.memberNames,
    required this.totalSpent,
  });

  static const List<Color> _chartColors = [
    AppColors.primary,
    AppColors.secondary,
    AppColors.gold,
    AppColors.negative,
    AppColors.warning,
    Color(0xFF26C6DA),
    Color(0xFFAB47BC),
    Color(0xFF66BB6A),
    Color(0xFFEF5350),
    Color(0xFF42A5F5),
  ];

  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat('#,##0', 'en_US');

    if (perPersonSpending.isEmpty || totalSpent == 0) {
      return const Center(
        child: Text(
          'No expenses yet',
          style: TextStyle(color: AppColors.textTertiary),
        ),
      );
    }

    final entries = perPersonSpending.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      children: [
        // Pie chart
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sections: entries.asMap().entries.map((e) {
                final index = e.key;
                final entry = e.value;
                final percentage = (entry.value / totalSpent * 100);
                final color = _chartColors[index % _chartColors.length];

                return PieChartSectionData(
                  value: entry.value,
                  color: color,
                  radius: 60,
                  title: '${percentage.toStringAsFixed(0)}%',
                  titleStyle: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                  titlePositionPercentageOffset: 0.6,
                );
              }).toList(),
              sectionsSpace: 2,
              centerSpaceRadius: 40,
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Legend
        ...entries.asMap().entries.map((e) {
          final index = e.key;
          final entry = e.value;
          final color = _chartColors[index % _chartColors.length];
          final name = memberNames[entry.key] ?? 'Unknown';
          final percentage = (entry.value / totalSpent * 100);

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Text(
                  '${numberFormat.format(entry.value)} EGP',
                  style: const TextStyle(
                    color: AppColors.gold,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 40,
                  child: Text(
                    '${percentage.toStringAsFixed(0)}%',
                    style: const TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

/// Per-person spending summary with progress bars.
class SpendingSummaryList extends StatelessWidget {
  final Map<String, double> perPersonSpending;
  final Map<String, double> balances;
  final Map<String, String> memberNames;
  final double fairShare;

  const SpendingSummaryList({
    super.key,
    required this.perPersonSpending,
    required this.balances,
    required this.memberNames,
    required this.fairShare,
  });

  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat('#,##0.00', 'en_US');
    final maxSpent = perPersonSpending.values.fold<double>(
      0,
      (max, v) => v > max ? v : max,
    );

    final entries = memberNames.entries.toList();

    return Column(
      children: entries.asMap().entries.map((e) {
        final index = e.key;
        final entry = e.value;
        final uid = entry.key;
        final name = entry.value;
        final spent = perPersonSpending[uid] ?? 0;
        final balance = balances[uid] ?? 0;
        final isPositive = balance >= 0;

        return TweenAnimationBuilder<double>(
          duration: Duration(milliseconds: 400 + (index * 80)),
          tween: Tween(begin: 0.0, end: 1.0),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Opacity(opacity: value, child: child);
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            padding: const EdgeInsets.all(16),
            decoration: GlassDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: (isPositive ? AppColors.positive : AppColors.negative)
                            .withValues(alpha: 0.15),
                      ),
                      child: Center(
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : '?',
                          style: TextStyle(
                            color: isPositive
                                ? AppColors.positive
                                : AppColors.negative,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Spent: ${numberFormat.format(spent)} EGP',
                            style: const TextStyle(
                              color: AppColors.textTertiary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${isPositive ? '+' : ''}${numberFormat.format(balance)} EGP',
                          style: TextStyle(
                            color: isPositive
                                ? AppColors.positive
                                : AppColors.negative,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          isPositive ? 'receives' : 'owes',
                          style: TextStyle(
                            color: (isPositive
                                    ? AppColors.positive
                                    : AppColors.negative)
                                .withValues(alpha: 0.7),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Progress bar
                TweenAnimationBuilder<double>(
                  duration: Duration(milliseconds: 600 + (index * 100)),
                  tween: Tween(begin: 0.0, end: maxSpent > 0 ? spent / maxSpent : 0),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: value,
                        backgroundColor: AppColors.glassFill,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isPositive ? AppColors.positive : AppColors.negative,
                        ),
                        minHeight: 6,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
