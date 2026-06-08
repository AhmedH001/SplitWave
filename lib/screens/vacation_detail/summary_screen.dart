import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/vacation.dart';
import '../../models/expense.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/settlement_card.dart';
import '../../widgets/summary_chart.dart';

class SummaryScreen extends StatelessWidget {
  final Vacation vacation;
  final List<Expense> expenses;

  const SummaryScreen({
    super.key,
    required this.vacation,
    required this.expenses,
  });

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();
    final currentUserId = AuthService().currentUser?.uid ?? '';
    final numberFormat = NumberFormat('#,##0.00', 'en_US');

    final total = firestoreService.calculateTotal(expenses);
    final perPerson = firestoreService.calculatePerPersonSpending(expenses);
    final balances =
        firestoreService.calculateBalances(expenses, vacation.memberNames);
    final settlements =
        firestoreService.calculateSettlements(expenses, vacation.memberNames);

    if (expenses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('📊', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 12),
            const Text(
              'No expenses to summarize',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Add some expenses first',
              style: TextStyle(
                color: AppColors.textTertiary,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Total overview card
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(20),
            decoration: GlassDecoration(highlight: true),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatColumn(
                  'Total',
                  '${numberFormat.format(total)} EGP',
                  AppColors.gold,
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: AppColors.glassBorder,
                ),
                _buildStatColumn(
                  'Members',
                  '${vacation.memberCount}',
                  AppColors.primary,
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: AppColors.glassBorder,
                ),
                _buildStatColumn(
                  'Expenses',
                  '${expenses.length}',
                  AppColors.secondary,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Section: Per-person spending
          _buildSectionHeader('💰 Spending Breakdown'),
          SpendingSummaryList(
            perPersonSpending: perPerson,
            balances: balances,
            memberNames: vacation.memberNames,
            fairShare: total / vacation.memberCount,
          ),

          const SizedBox(height: 24),

          // Section: Settlements
          _buildSectionHeader('🤝 Settlement Plan'),
          if (settlements.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Text(
                'Everyone is settled up! 🎉',
                style: TextStyle(
                  color: AppColors.positive,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                '${settlements.length} transaction${settlements.length > 1 ? 's' : ''} to settle up',
                style: const TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 8),
            ...settlements.asMap().entries.map((entry) {
              return SettlementCard(
                settlement: entry.value,
                index: entry.key,
                currentUserId: currentUserId,
                vacationId: vacation.id,
              );
            }),
          ],

          const SizedBox(height: 24),

          // Section: Chart
          _buildSectionHeader('📊 Spending Distribution'),
          const SizedBox(height: 8),
          SummaryChart(
            perPersonSpending: perPerson,
            memberNames: vacation.memberNames,
            totalSpent: total,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textTertiary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
