import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/group.dart';
import '../providers/app_state.dart';
import '../providers/expenses_provider.dart';
import '../providers/groups_provider.dart';
import '../widgets/group_card.dart';
import 'group_form_screen.dart';
import '../widgets/home_quick_actions.dart';
import '../widgets/home_stats_section.dart';
import '../theme/app_colors.dart';

class GroupsScreen extends StatelessWidget {
  final ValueChanged<String> onOpenGroup;

  const GroupsScreen({super.key, required this.onOpenGroup});

  void _openEditGroup(BuildContext context, Group group) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => GroupFormScreen(existingGroup: group)),
    );
  }

  Widget _buildBrandHeader(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          'tricount',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(width: 8),
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            'by zied',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Column(
      children: [
        Text(
          'No tricounts here',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Tap on "+" to add a tricount',
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontal = constraints.maxWidth >= 600 ? 28.0 : 20.0;
        return Consumer3<GroupsProvider, ExpensesProvider, AppState>(
          builder:
              (context, groupsProvider, expensesProvider, appState, child) {
                final groups = groupsProvider.groups;
                final expenses = expensesProvider.getAllExpenses();
                final stats = computeHomeStats(
                  groups: groups,
                  expenses: expenses,
                );

                final cards = groups
                    .map(
                      (group) => GroupCard(
                        group: group,
                        selected: group.id == appState.selectedGroupId,
                        onTap: () {
                          context.read<AppState>().selectedGroupId = group.id;
                          onOpenGroup(group.id);
                        },
                        onEdit: () => _openEditGroup(context, group),
                        onDelete: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Delete tricount?'),
                              content: Text(
                                'Delete ${group.name} and its expenses?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(false),
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(true),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            if (!context.mounted) {
                              return;
                            }
                            await context
                                .read<ExpensesProvider>()
                                .deleteExpensesForGroup(group.id);
                            await context.read<GroupsProvider>().deleteGroup(
                              group.id,
                            );
                            // Activity log removed
                          }
                        },
                      ),
                    )
                    .toList();

                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: SafeArea(
                    child: ListView(
                      key: const ValueKey('list'),
                      padding: EdgeInsets.fromLTRB(
                        horizontal,
                        12,
                        horizontal,
                        140,
                      ),
                      physics: const BouncingScrollPhysics(),
                      children: [
                        _buildBrandHeader(context),
                        const SizedBox(height: 24),
                        HomeStatsSection(stats: stats),
                        const SizedBox(height: 20),
                        const HomeQuickActions(),
                        if (groups.isEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            'Create a group to start adding expenses.',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                        const SizedBox(height: 20),
                        if (groups.isEmpty) ...[
                          _buildEmptyState(context),
                        ] else
                          ...cards
                              .expand(
                                (card) => [card, const SizedBox(height: 12)],
                              )
                              .toList(),
                      ],
                    ),
                  ),
                );
              },
        );
      },
    );
  }
}
