import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/expense.dart';
import '../models/payment.dart';
import '../models/group.dart';
import '../providers/expenses_provider.dart';
import '../providers/groups_provider.dart';
import '../providers/payments_provider.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';
import '../utils/split_calculator.dart';
import 'expense_details_screen.dart';
import 'group_form_screen.dart';
import 'expense_form_screen.dart';
import '../widgets/labeled_fab.dart';
import '../widgets/empty_state.dart';

class GroupDetailsScreen extends StatefulWidget {
  final String groupId;

  const GroupDetailsScreen({super.key, required this.groupId});

  @override
  State<GroupDetailsScreen> createState() => _GroupDetailsScreenState();
}

class _GroupDetailsScreenState extends State<GroupDetailsScreen> {
  int _segment = 0;

  String _newId(String prefix) {
    return '${prefix}_${DateTime.now().microsecondsSinceEpoch}';
  }

  void _setSegment(int? value) {
    if (value == null) {
      return;
    }
    setState(() {
      _segment = value;
    });
  }

  void _openAddExpense() {
    final group = context.read<GroupsProvider>().getById(widget.groupId);
    if (group == null) {
      return;
    }
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => ExpenseFormScreen(group: group)));
  }

  void _editGroup(Group group) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => GroupFormScreen(existingGroup: group)),
    );
  }

  Future<void> _deleteGroup(Group group) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Group'),
        content: Text(
          'Are you sure you want to delete "${group.name}"? All expenses and data will be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await context.read<ExpensesProvider>().deleteExpensesForGroup(group.id);
      await context.read<GroupsProvider>().deleteGroup(group.id);
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  void _editExpense(Expense expense, String groupId) {
    final group = context.read<GroupsProvider>().getById(groupId);
    if (group == null) {
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            ExpenseFormScreen(group: group, existingExpense: expense),
      ),
    );
  }

  Future<void> _deleteExpense(Expense expense, String groupId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete expense?'),
        content: Text('Delete ${expense.title}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) {
      return;
    }
    if (!context.mounted) {
      return;
    }

    await context.read<ExpensesProvider>().deleteExpense(expense.id);
    // Activity log removed
  }

  Future<void> _markSettlementPaid(
    Settlement settlement,
    String groupId,
  ) async {
    final payment = Payment(
      id: _newId('p'),
      groupId: groupId,
      fromMemberId: settlement.from.id,
      toMemberId: settlement.to.id,
      amountEur: settlement.amount,
      date: DateTime.now(),
    );
    await context.read<PaymentsProvider>().addPayment(payment);
    // Activity log removed
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Payment marked as paid')));
  }

  Future<void> _markPaymentUnpaid(
    Payment payment,
    String groupId,
    Map<String, String> memberNames,
  ) async {
    final fromName = memberNames[payment.fromMemberId] ?? 'Unknown';
    final toName = memberNames[payment.toMemberId] ?? 'Unknown';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark as unpaid?'),
        content: Text('Remove payment from $fromName to $toName?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirm != true) {
      return;
    }
    if (!context.mounted) {
      return;
    }

    await context.read<PaymentsProvider>().deletePayment(payment.id);
    // Activity log removed
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Payment marked as unpaid')));
  }

  Widget _buildHeader(BuildContext context, String name) {
    final surfaceMuted = AppColors.surfaceMuted;

    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: surfaceMuted,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Icon(
            Icons.beach_access_outlined,
            color: Theme.of(context).colorScheme.primary,
            size: 36,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          name,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  Widget _buildSegmentControl(BuildContext context) {
    final surfaceMuted = AppColors.surfaceMuted;
    final surface = Theme.of(context).colorScheme.surface;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: surfaceMuted,
        borderRadius: BorderRadius.circular(18),
      ),
      child: CupertinoSlidingSegmentedControl<int>(
        groupValue: _segment,
        thumbColor: surface,
        backgroundColor: surfaceMuted,
        onValueChanged: _setSegment,
        children: const {
          0: Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Text('Expenses'),
          ),
          1: Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Text('Balances'),
          ),
        },
      ),
    );
  }

  Widget _buildExpensesContent(
    BuildContext context,
    List<Expense> expenses,
    Map<String, String> memberNames,
    String groupId,
  ) {
    if (expenses.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          children: [
            Icon(
              Icons.search,
              size: 64,
              color: Theme.of(context).iconTheme.color?.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No Expenses Yet',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Add an expense by tapping on the "+" to start tracking.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      children: expenses.map((expense) {
        final surfaceMuted = AppColors.surfaceMuted;
        final surface = Theme.of(context).colorScheme.surface;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Material(
            color: surfaceMuted,
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ExpenseDetailsScreen(
                      groupId: groupId,
                      expenseId: expense.id,
                    ),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.receipt_long_outlined,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            expense.title,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Paid by ${memberNames[expense.payerMemberId] ?? 'Unknown'}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          formatEur(expense.amountEur),
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formatDate(expense.date),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(width: 4),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') {
                          _editExpense(expense, groupId);
                        }
                        if (value == 'delete') {
                          _deleteExpense(expense, groupId);
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: 'edit', child: Text('Edit')),
                        PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                      icon: Icon(
                        Icons.more_horiz,
                        color: Theme.of(context).iconTheme.color,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBalancesContent(
    BuildContext context,
    List<BalanceEntry> balances,
    List<Settlement> settlements,
    List<Payment> payments,
    Map<String, String> memberNames,
    String groupId,
  ) {
    final allSettled = settlements.isEmpty;
    final surfaceMuted = AppColors.surfaceMuted;
    final surface = Theme.of(context).colorScheme.surface;
    final successColor = AppColors.success;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (allSettled)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: surfaceMuted,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: surface,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.thumb_up_alt_outlined, color: successColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'All Good!',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "You don't need to balance",
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: Theme.of(context).iconTheme.color,
                ),
              ],
            ),
          ),
        if (allSettled) const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Balances', style: Theme.of(context).textTheme.titleMedium),
            IconButton(
              onPressed: () {},
              icon: Icon(
                Icons.swap_vert,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (balances.isEmpty)
          const EmptyState(
            title: 'No balances yet',
            message: 'Add expenses to calculate balances.',
          )
        else
          ...balances.map((entry) {
            final isZero = entry.amount.abs() < 0.01;
            final amountColor = isZero
                ? AppColors.textMuted
                : entry.amount >= 0
                ? AppColors.primary
                : AppColors.textSecondary;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.surface,
                      child: Text(
                        entry.member.name.isEmpty
                            ? '?'
                            : entry.member.name[0].toUpperCase(),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        entry.member.name,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    Text(
                      formatEur(entry.amount),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: amountColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        const SizedBox(height: 12),
        Text('Settlements', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (settlements.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              'All settled up',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
          )
        else
          ...settlements.map(
            (settlement) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: AppColors.surface,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_forward_rounded,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${settlement.from.name} pays ${settlement.to.name}',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Mark as paid when done',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          formatEur(settlement.amount),
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        IconButton(
                          onPressed: () =>
                              _markSettlementPaid(settlement, groupId),
                          icon: const Icon(
                            Icons.check_circle,
                            color: AppColors.success,
                          ),
                          tooltip: 'Mark as paid',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        const SizedBox(height: 12),
        Text('Paid', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (payments.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              'No paid payments yet',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
          )
        else
          ...payments.map((payment) {
            final fromName = memberNames[payment.fromMemberId] ?? 'Unknown';
            final toName = memberNames[payment.toMemberId] ?? 'Unknown';
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: AppColors.surface,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle_outline,
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$fromName paid $toName',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            formatDate(payment.date),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          formatEur(payment.amountEur),
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        IconButton(
                          onPressed: () =>
                              _markPaymentUnpaid(payment, groupId, memberNames),
                          icon: const Icon(
                            Icons.undo,
                            color: AppColors.textSecondary,
                          ),
                          tooltip: 'Mark as unpaid',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final group = context.watch<GroupsProvider>().getById(widget.groupId);
    if (group == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Tricounts')),
        body: const EmptyState(
          title: 'Tricount not found',
          message: 'Please go back and select another one.',
        ),
      );
    }

    final expenses = context.watch<ExpensesProvider>().expenses;
    final payments = context.watch<PaymentsProvider>().payments;
    final memberNames = {
      for (final member in group.members) member.id: member.name,
    };

    final balances = calculateBalances(group.members, expenses, payments);
    final settlements = calculateSettlements(balances);

    Widget content;
    if (_segment == 1) {
      content = _buildBalancesContent(
        context,
        balances,
        settlements,
        payments,
        memberNames,
        group.id,
      );
    } else {
      content = _buildExpensesContent(context, expenses, memberNames, group.id);
    }

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(color: AppColors.primary),
        title: const Text('tricounts'),
        actions: [
          IconButton(
            onPressed: () => _editGroup(group),
            icon: const Icon(Icons.edit),
            tooltip: 'Edit Group',
            style: IconButton.styleFrom(
              backgroundColor: AppColors.surfaceMuted,
              shape: const CircleBorder(),
            ),
          ),
          IconButton(
            onPressed: () => _deleteGroup(group),
            icon: const Icon(Icons.delete),
            tooltip: 'Delete Group',
            style: IconButton.styleFrom(
              backgroundColor: AppColors.surfaceMuted,
              shape: const CircleBorder(),
            ),
          ),
          // History removed
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
        physics: const BouncingScrollPhysics(),
        children: [
          _buildHeader(context, group.name),
          const SizedBox(height: 20),
          _buildSegmentControl(context),
          const SizedBox(height: 20),
          content,
        ],
      ),
      floatingActionButton: _segment == 0
          ? LabeledFab(
              label: 'Add Expense',
              icon: Icons.add,
              onPressed: _openAddExpense,
              heroTag: 'add_expense_fab',
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
