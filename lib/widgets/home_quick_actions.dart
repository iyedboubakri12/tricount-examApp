import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/group.dart';
import '../providers/app_state.dart';
import '../providers/exchange_rate_provider.dart';
import '../providers/groups_provider.dart';
import '../theme/app_colors.dart';
import '../screens/group_form_screen.dart';
import '../screens/expense_form_screen.dart';

class HomeQuickActions extends StatelessWidget {
  const HomeQuickActions({super.key});

  Future<void> _refreshRate(BuildContext context) async {
    final provider = context.read<ExchangeRateProvider>();
    final rate = await provider.fetchRate();
    if (!context.mounted) {
      return;
    }
    if (rate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not fetch EUR to USD rate')),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('1 EUR = ${rate.toStringAsFixed(3)} USD')),
    );
  }

  void _showAddExpense(
    BuildContext context, {
    required Group? group,
    required bool hasGroups,
  }) {
    if (!hasGroups) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Create a group first')));
      return;
    }
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => ExpenseFormScreen(group: group)));
  }

  @override
  Widget build(BuildContext context) {
    final groupsProvider = context.watch<GroupsProvider>();
    final appState = context.watch<AppState>();
    final rateProvider = context.watch<ExchangeRateProvider>();
    final selectedGroupId = appState.selectedGroupId;
    final selectedGroup = selectedGroupId == null
        ? null
        : groupsProvider.getById(selectedGroupId);
    final hasGroups = groupsProvider.groups.isNotEmpty;

    final primaryColor = Theme.of(context).colorScheme.primary;
    final primarySoft = AppColors.primarySoft;
    final surfaceColor = Theme.of(context).colorScheme.surface;

    final actions = [
      _QuickActionData(
        label: 'Add Expense',
        icon: Icons.add,
        iconColor: primaryColor,
        iconBg: primarySoft,
        enabled: true,
        onTap: () => _showAddExpense(
          context,
          group: selectedGroup,
          hasGroups: hasGroups,
        ),
      ),
      _QuickActionData(
        label: 'Create Group',
        icon: Icons.group_add,
        iconColor: primaryColor,
        iconBg: surfaceColor,
        enabled: true,
        onTap: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const GroupFormScreen())),
      ),
      _QuickActionData(
        label: rateProvider.isLoading ? 'Refreshing...' : 'EUR to USD',
        icon: Icons.currency_exchange,
        iconColor: primaryColor,
        iconBg: surfaceColor,
        enabled: !rateProvider.isLoading,
        onTap: rateProvider.isLoading ? null : () => _refreshRate(context),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        // Use more columns on wider screens for a clean grid.
        final columns = maxWidth >= 900
            ? 4
            : maxWidth >= 600
            ? 3
            : 2;
        final spacing = 12.0;
        final itemWidth = (maxWidth - spacing * (columns - 1)) / columns;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: actions
                  .map(
                    (action) => SizedBox(
                      width: itemWidth,
                      child: _QuickActionCard(data: action),
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

class _QuickActionData {
  final String label;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final bool enabled;
  final VoidCallback? onTap;

  const _QuickActionData({
    required this.label,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.enabled,
    required this.onTap,
  });
}

class _QuickActionCard extends StatefulWidget {
  final _QuickActionData data;

  const _QuickActionCard({required this.data});

  @override
  State<_QuickActionCard> createState() => _QuickActionCardState();
}

class _QuickActionCardState extends State<_QuickActionCard> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (!widget.data.enabled) {
      return;
    }
    setState(() {
      _pressed = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final surfaceMuted = AppColors.surfaceMuted;

    return AnimatedScale(
      duration: const Duration(milliseconds: 120),
      scale: _pressed ? 0.98 : 1.0,
      child: Material(
        color: surfaceMuted,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: widget.data.onTap,
          onTapDown: (_) => _setPressed(true),
          onTapUp: (_) => _setPressed(false),
          onTapCancel: () => _setPressed(false),
          child: Opacity(
            opacity: widget.data.enabled ? 1.0 : 0.45,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: widget.data.iconBg,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      widget.data.icon,
                      color: widget.data.iconColor,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.data.label,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
