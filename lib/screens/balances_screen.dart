import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/payment.dart';
import '../providers/app_state.dart';
import '../providers/expenses_provider.dart';
import '../providers/groups_provider.dart';
import '../providers/payments_provider.dart';
import '../utils/formatters.dart';
import '../utils/split_calculator.dart';
import '../widgets/balance_tile.dart';
import '../widgets/empty_state.dart';
import '../widgets/settlement_tile.dart';

class BalancesScreen extends StatelessWidget {
  final VoidCallback onGoToExpenses;

  const BalancesScreen({super.key, required this.onGoToExpenses});

  String _newId(String prefix) {
    return '${prefix}_${DateTime.now().microsecondsSinceEpoch}';
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final padding = constraints.maxWidth >= 600 ? 24.0 : 16.0;
        final isWide = constraints.maxWidth >= 600;

        return Consumer4<
          GroupsProvider,
          ExpensesProvider,
          PaymentsProvider,
          AppState
        >(
          builder:
              (
                context,
                groupsProvider,
                expensesProvider,
                paymentsProvider,
                appState,
                child,
              ) {
                final groupId = appState.selectedGroupId;
                if (groupId == null) {
                  return EmptyState(
                    title: 'Pick a group',
                    message: 'Select a group to see balances.',
                    actions: [
                      ElevatedButton(
                        onPressed: onGoToExpenses,
                        child: const Text('Go to Expenses'),
                      ),
                    ],
                  );
                }

                final group = groupsProvider.getById(groupId);
                if (group == null) {
                  return EmptyState(
                    title: 'Group not found',
                    message: 'Please select another group.',
                    actions: [
                      ElevatedButton(
                        onPressed: onGoToExpenses,
                        child: const Text('Go to Expenses'),
                      ),
                    ],
                  );
                }

                final expenses = expensesProvider.expenses;
                final payments = paymentsProvider.payments;
                if (expenses.isEmpty) {
                  return EmptyState(
                    title: 'No balances yet',
                    message:
                        'Add expenses to calculate balances and settlements.',
                    actions: [
                      ElevatedButton(
                        onPressed: onGoToExpenses,
                        child: const Text('Add expenses'),
                      ),
                    ],
                  );
                }

                final balances = calculateBalances(
                  group.members,
                  expenses,
                  payments,
                );
                final settlements = calculateSettlements(balances);

                final balanceTiles = balances
                    .map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: BalanceTile(
                          name: entry.member.name,
                          amountText: formatEur(entry.amount),
                          isPositive: entry.amount >= 0,
                        ),
                      ),
                    )
                    .toList();

                final settlementTiles = settlements.isEmpty
                    ? [
                        Card(
                          child: ListTile(
                            title: const Text('All settled up'),
                            subtitle: const Text('No payments needed.'),
                          ),
                        ),
                      ]
                    : settlements
                          .map(
                            (settlement) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: SettlementTile(
                                from: settlement.from.name,
                                to: settlement.to.name,
                                amountText: formatEur(settlement.amount),
                                onMarkPaid: () async {
                                  // Save a payment so balances update and history shows it.
                                  final payment = Payment(
                                    id: _newId('p'),
                                    groupId: group.id,
                                    fromMemberId: settlement.from.id,
                                    toMemberId: settlement.to.id,
                                    amountEur: settlement.amount,
                                    date: DateTime.now(),
                                  );
                                  await context
                                      .read<PaymentsProvider>()
                                      .addPayment(payment);
                                  // Activity log removed
                                  if (!context.mounted) {
                                    return;
                                  }
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Payment marked as paid'),
                                    ),
                                  );
                                },
                              ),
                            ),
                          )
                          .toList();

                if (isWide) {
                  return ListView(
                    padding: EdgeInsets.all(padding),
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Balances',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 12),
                                ...balanceTiles,
                              ],
                            ),
                          ),
                          SizedBox(width: padding),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Settlements',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 12),
                                ...settlementTiles,
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                }

                return ListView(
                  padding: EdgeInsets.all(padding),
                  children: [
                    Text(
                      'Balances',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    ...balanceTiles,
                    const SizedBox(height: 8),
                    Text(
                      'Settlements',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    ...settlementTiles,
                  ],
                );
              },
        );
      },
    );
  }
}
