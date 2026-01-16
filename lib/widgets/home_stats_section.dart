import 'package:flutter/material.dart';

import '../models/expense.dart';
import '../models/group.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';

class HomeStats {
  final int totalGroups;
  final int totalExpenses;
  final double monthTotal;
  final int membersCount;

  const HomeStats({
    required this.totalGroups,
    required this.totalExpenses,
    required this.monthTotal,
    required this.membersCount,
  });
}

// Helper for the home dashboard numbers.
HomeStats computeHomeStats({
  required List<Group> groups,
  required List<Expense> expenses,
  Group? selectedGroup,
}) {
  final now = DateTime.now();
  final monthTotal = expenses
      .where(
        (expense) =>
            expense.date.year == now.year && expense.date.month == now.month,
      )
      .fold(0.0, (sum, expense) => sum + expense.amountEur);

  final membersCount = selectedGroup == null
      ? groups.fold(0, (sum, group) => sum + group.members.length)
      : selectedGroup.members.length;

  return HomeStats(
    totalGroups: groups.length,
    totalExpenses: expenses.length,
    monthTotal: monthTotal,
    membersCount: membersCount,
  );
}

class HomeStatsSection extends StatelessWidget {
  final HomeStats stats;

  const HomeStatsSection({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final columns = maxWidth >= 900
            ? 4
            : maxWidth >= 600
            ? 3
            : 2;
        final spacing = 12.0;
        final cardWidth = (maxWidth - spacing * (columns - 1)) / columns;

        final bgColor = AppColors.surfaceMuted;

        final items = [
          _StatItem(
            icon: Icons.group,
            color: bgColor,
            value: stats.totalGroups.toString(),
            label: 'Total Groups',
          ),
          _StatItem(
            icon: Icons.receipt_long,
            color: bgColor,
            value: stats.totalExpenses.toString(),
            label: 'Total Expenses',
          ),
          _StatItem(
            icon: Icons.calendar_month,
            color: bgColor,
            value: formatEur(stats.monthTotal),
            label: 'This Month',
          ),
          _StatItem(
            icon: Icons.person,
            color: bgColor,
            value: stats.membersCount.toString(),
            label: 'Members',
          ),
        ];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Quick Stats', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: items
                  .map(
                    (item) => SizedBox(
                      width: cardWidth,
                      child: _StatCard(item: item),
                    ),
                  )
                  .toList(),
            ),
          ],
        );
      },
    );
  }
}

class _StatItem {
  final IconData icon;
  final Color color;
  final String value;
  final String label;

  const _StatItem({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });
}

class _StatCard extends StatelessWidget {
  final _StatItem item;

  const _StatCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.outline),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: item.color,
              shape: BoxShape.circle,
            ),
            child: Icon(
              item.icon,
              color: Theme.of(context).colorScheme.primary,
              size: 18,
            ),
          ),
          const SizedBox(height: 10),
          Text(item.value, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(item.label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
