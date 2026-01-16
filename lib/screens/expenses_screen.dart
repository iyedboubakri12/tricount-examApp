import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_state.dart';
import '../providers/expenses_provider.dart';
import '../providers/groups_provider.dart';
import '../utils/formatters.dart';
import '../widgets/empty_state.dart';
import '../widgets/expense_tile.dart';
import 'expense_details_screen.dart';
import 'expense_form_screen.dart';

class ExpensesScreen extends StatelessWidget {
  final VoidCallback onAddExpense;
  final VoidCallback onGoToGroups;

  const ExpensesScreen({
    super.key,
    required this.onAddExpense,
    required this.onGoToGroups,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final padding = constraints.maxWidth >= 600 ? 24.0 : 16.0;
        return Consumer3<GroupsProvider, ExpensesProvider, AppState>(
          builder:
              (context, groupsProvider, expensesProvider, appState, child) {
                final groupId = appState.selectedGroupId;
                if (groupId == null) {
                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: EmptyState(
                      key: const ValueKey('no-group'),
                      title: 'Pick a group',
                      message: 'Select a group to see its expenses.',
                      actions: [
                        ElevatedButton(
                          onPressed: onGoToGroups,
                          child: const Text('Go to Groups'),
                        ),
                      ],
                    ),
                  );
                }

                final group = groupsProvider.getById(groupId);
                if (group == null) {
                  return EmptyState(
                    title: 'Group not found',
                    message: 'Please select another group.',
                    actions: [
                      ElevatedButton(
                        onPressed: onGoToGroups,
                        child: const Text('Go to Groups'),
                      ),
                    ],
                  );
                }

                final expenses = expensesProvider.expenses;
                final memberNames = {
                  for (final member in group.members) member.id: member.name,
                };

                if (expenses.isEmpty) {
                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: EmptyState(
                      key: const ValueKey('empty-expenses'),
                      title: 'No expenses yet',
                      message: 'Add the first expense for ${group.name}.',
                      actions: [
                        ElevatedButton(
                          onPressed: onAddExpense,
                          child: const Text('Add expense'),
                        ),
                      ],
                    ),
                  );
                }

                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: ListView(
                    key: const ValueKey('expense-list'),
                    padding: EdgeInsets.all(padding),
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                group.name,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${group.members.length} members',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...expenses.map(
                        (expense) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: ExpenseTile(
                            expense: expense,
                            payerName:
                                memberNames[expense.payerMemberId] ?? 'Unknown',
                            amountText: formatEur(expense.amountEur),
                            dateText: formatDate(expense.date),
                            convertedText: expense.convertedAmountUsd == null
                                ? null
                                : formatUsd(expense.convertedAmountUsd!),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ExpenseDetailsScreen(
                                    groupId: group.id,
                                    expenseId: expense.id,
                                  ),
                                ),
                              );
                            },
                            onEdit: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ExpenseFormScreen(
                                    group: group,
                                    existingExpense: expense,
                                  ),
                                ),
                              );
                            },
                            onDelete: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Delete expense?'),
                                  content: Text('Delete ${expense.title}?'),
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
                                await context
                                    .read<ExpensesProvider>()
                                    .deleteExpense(expense.id);
                                // Activity log removed
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
        );
      },
    );
  }
}
