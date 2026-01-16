import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/expense.dart';
import '../models/group.dart';
import '../providers/expenses_provider.dart';
import '../providers/exchange_rate_provider.dart';
import '../providers/groups_provider.dart';
import '../utils/formatters.dart';
import '../widgets/empty_state.dart';
import 'expense_form_screen.dart';

class ExpenseDetailsScreen extends StatefulWidget {
  final String groupId;
  final String expenseId;

  const ExpenseDetailsScreen({
    super.key,
    required this.groupId,
    required this.expenseId,
  });

  @override
  State<ExpenseDetailsScreen> createState() => _ExpenseDetailsScreenState();
}

class _ExpenseDetailsScreenState extends State<ExpenseDetailsScreen> {
  bool _isConverting = false;

  Expense? _findExpense(List<Expense> expenses) {
    for (final expense in expenses) {
      if (expense.id == widget.expenseId) {
        return expense;
      }
    }
    return null;
  }

  Future<void> _convertToUsd(Expense expense) async {
    setState(() {
      _isConverting = true;
    });

    final rate = await context.read<ExchangeRateProvider>().fetchRate();

    if (!mounted) {
      return;
    }

    setState(() {
      _isConverting = false;
    });

    if (rate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to fetch exchange rate')),
      );
      return;
    }

    final updated = Expense(
      id: expense.id,
      groupId: expense.groupId,
      title: expense.title,
      amountEur: expense.amountEur,
      payerMemberId: expense.payerMemberId,
      participantIds: expense.participantIds,
      date: expense.date,
      convertedAmountUsd: expense.amountEur * rate,
    );

    await context.read<ExpensesProvider>().addExpense(updated);
  }

  void _showEditSheet(BuildContext context, Expense expense, Group group) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            ExpenseFormScreen(group: group, existingExpense: expense),
      ),
    );
  }

  Future<void> _deleteExpense(Expense expense) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Expense'),
        content: Text('Are you sure you want to delete "${expense.title}"?'),
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
      await context.read<ExpensesProvider>().deleteExpense(expense.id);
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final group = context.watch<GroupsProvider>().getById(widget.groupId);
    if (group == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Expense')),
        body: const EmptyState(
          title: 'Group not found',
          message: 'Please go back and try again.',
        ),
      );
    }

    final expenses = context.watch<ExpensesProvider>().expenses;
    final expense = _findExpense(expenses);
    if (expense == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Expense')),
        body: const EmptyState(
          title: 'Expense not found',
          message: 'Please go back and try again.',
        ),
      );
    }

    final memberNames = {
      for (final member in group.members) member.id: member.name,
    };
    final payer = memberNames[expense.payerMemberId] ?? 'Unknown';
    final participants = expense.participantIds
        .map((id) => memberNames[id] ?? 'Unknown')
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Details'),
        actions: [
          IconButton(
            onPressed: () => _showEditSheet(context, expense, group),
            icon: const Icon(Icons.edit),
            tooltip: 'Edit',
          ),
          IconButton(
            onPressed: () => _deleteExpense(expense),
            icon: const Icon(Icons.delete),
            tooltip: 'Delete',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    expense.title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text('Amount: ${formatEur(expense.amountEur)}'),
                  if (expense.convertedAmountUsd != null)
                    Text('USD: ${formatUsd(expense.convertedAmountUsd!)}'),
                  const SizedBox(height: 8),
                  Text('Payer: $payer'),
                  Text('Date: ${formatDate(expense.date)}'),
                  const SizedBox(height: 8),
                  Text('Participants: ${participants.join(", ")}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _isConverting ? null : () => _convertToUsd(expense),
            icon: const Icon(Icons.currency_exchange),
            label: Text(_isConverting ? 'Converting...' : 'Convert to USD'),
          ),
        ],
      ),
    );
  }
}
