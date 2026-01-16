import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/expense.dart';
import '../models/group.dart';
import '../models/member.dart';
import '../providers/expenses_provider.dart';
import '../providers/exchange_rate_provider.dart';
import '../providers/groups_provider.dart';
import '../utils/formatters.dart';

Future<void> showExpenseFormSheet(
  BuildContext context, {
  Group? group,
  Expense? existingExpense,
}) {
  assert(existingExpense == null || group != null);
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) =>
        ExpenseFormSheet(group: group, existingExpense: existingExpense),
  );
}

class ExpenseFormSheet extends StatefulWidget {
  final Group? group;
  final Expense? existingExpense;

  const ExpenseFormSheet({
    super.key,
    required this.group,
    this.existingExpense,
  });

  @override
  State<ExpenseFormSheet> createState() => _ExpenseFormSheetState();
}

class _ExpenseFormSheetState extends State<ExpenseFormSheet> {
  static int _seed = 0;

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _payerController = TextEditingController();
  final _participantsController = TextEditingController();
  late DateTime _date;
  Group? _selectedGroup;
  double? _convertedUsd;
  double? _lastRate;
  bool _isSaving = false;
  bool _isConverting = false;

  bool get _isEditing => widget.existingExpense != null;
  bool get _canChangeGroup => !_isEditing;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingExpense;
    _date = existing?.date ?? DateTime.now();
    _selectedGroup = widget.group;
    _convertedUsd = existing?.convertedAmountUsd;
    _titleController.text = existing?.title ?? '';
    if (existing != null) {
      _amountController.text = existing.amountEur.toStringAsFixed(2);
    }
    if (existing != null && widget.group != null) {
      final memberNames = {
        for (final member in widget.group!.members) member.id: member.name,
      };
      _payerController.text = memberNames[existing.payerMemberId] ?? '';
      final participantNames = existing.participantIds
          .map((id) => memberNames[id] ?? '')
          .where((name) => name.isNotEmpty)
          .toList();
      _participantsController.text = participantNames.join(', ');
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _payerController.dispose();
    _participantsController.dispose();
    super.dispose();
  }

  String _newId(String prefix) {
    _seed += 1;
    return '${prefix}_${DateTime.now().microsecondsSinceEpoch}_$_seed';
  }

  double? _parseAmount() {
    final raw = _amountController.text.trim().replaceAll(',', '.');
    return double.tryParse(raw);
  }

  void _setGroup(Group? group) {
    setState(() {
      _selectedGroup = group;
      _payerController.clear();
      _participantsController.clear();
    });
  }

  List<String> _parseNames(String raw) {
    final cleaned = raw.replaceAll('\n', ',');
    final parts = cleaned.split(',');
    final seen = <String>{};
    final names = <String>[];
    for (final part in parts) {
      final name = part.trim();
      if (name.isEmpty) {
        continue;
      }
      final key = name.toLowerCase();
      if (seen.add(key)) {
        names.add(name);
      }
    }
    return names;
  }

  Future<void> _convertToUsd() async {
    final amount = _parseAmount();
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid amount first')),
      );
      return;
    }

    setState(() {
      _isConverting = true;
    });

    double? rate;
    try {
      rate = await context.read<ExchangeRateProvider>().fetchRate();
    } finally {
      if (mounted) {
        setState(() {
          _isConverting = false;
        });
      }
    }

    if (!mounted) {
      return;
    }

    if (rate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to fetch exchange rate')),
      );
      return;
    }

    final safeRate = rate;
    setState(() {
      _convertedUsd = amount * safeRate;
      _lastRate = safeRate;
    });
  }

  Future<void> _clearRateCache() async {
    await context.read<ExchangeRateProvider>().clearCached();
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Exchange rate cache cleared')),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _date = picked;
      });
    }
  }

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedGroup == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Select a tricount first')));
      return;
    }

    final payerName = _payerController.text.trim();
    if (payerName.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter a payer name')));
      return;
    }

    final participantNames = _parseNames(_participantsController.text);
    if (participantNames.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter at least one participant')),
      );
      return;
    }

    final amount = _parseAmount();
    if (amount == null || amount <= 0) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final group = _selectedGroup!;
    final memberByName = <String, Member>{
      for (final member in group.members) member.name.toLowerCase(): member,
    };
    final newMembers = <Member>[];

    Member getOrCreate(String name) {
      final key = name.toLowerCase();
      final existing = memberByName[key];
      if (existing != null) {
        return existing;
      }
      final member = Member(id: _newId('m'), name: name);
      memberByName[key] = member;
      newMembers.add(member);
      return member;
    }

    final payer = getOrCreate(payerName);
    final participantIds = participantNames
        .map((name) => getOrCreate(name).id)
        .toList();

    if (newMembers.isNotEmpty) {
      final updated = Group(
        id: group.id,
        name: group.name,
        members: [...group.members, ...newMembers],
      );
      await context.read<GroupsProvider>().updateGroup(updated);
    }

    final expense = Expense(
      id: widget.existingExpense?.id ?? _newId('e'),
      groupId: group.id,
      title: _titleController.text.trim(),
      amountEur: amount,
      payerMemberId: payer.id,
      participantIds: participantIds,
      date: _date,
      convertedAmountUsd: _convertedUsd,
    );

    await context.read<ExpensesProvider>().addExpense(expense);
    // Activity log removed

    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final groups = context.watch<GroupsProvider>().groups;
    final selectedGroup = _selectedGroup;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _isEditing ? 'Edit expense' : 'Add expense',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              if (_canChangeGroup)
                if (groups.isEmpty)
                  Text(
                    'Create a tricount first to add expenses.',
                    style: Theme.of(context).textTheme.bodySmall,
                  )
                else
                  DropdownButtonFormField<String>(
                    value: selectedGroup?.id,
                    decoration: const InputDecoration(labelText: 'Tricount'),
                    items: groups
                        .map(
                          (group) => DropdownMenuItem(
                            value: group.id,
                            child: Text(group.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      final group = groups.firstWhere((g) => g.id == value);
                      _setGroup(group);
                    },
                  )
              else
                Text(
                  'Tricount: ${selectedGroup?.name ?? ''}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(labelText: 'Amount (EUR)'),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (value) {
                  final amount = _parseAmount();
                  if (amount == null || amount <= 0) {
                    return 'Enter a valid amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _isConverting ? null : _convertToUsd,
                    icon: const Icon(Icons.currency_exchange),
                    label: Text(
                      _isConverting ? 'Converting...' : 'Convert to USD',
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (_convertedUsd != null)
                    Text(
                      formatUsd(_convertedUsd!),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                ],
              ),
              if (_lastRate != null) ...[
                const SizedBox(height: 6),
                Text(
                  'Rate: 1 EUR = ${_lastRate!.toStringAsFixed(3)} USD',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: _clearRateCache,
                  child: const Text('Clear cached rate'),
                ),
              ),
              const SizedBox(height: 12),
              if (selectedGroup == null)
                Text(
                  'Select a tricount to add payer and participants.',
                  style: Theme.of(context).textTheme.bodySmall,
                )
              else
                TextFormField(
                  controller: _payerController,
                  decoration: const InputDecoration(labelText: 'Payer name'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter a payer name';
                    }
                    return null;
                  },
                ),
              const SizedBox(height: 16),
              Card(
                child: ListTile(
                  title: const Text('Date'),
                  subtitle: Text(formatDate(_date)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: _pickDate,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Participants',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              if (selectedGroup == null)
                const Text('Pick a tricount first.')
              else
                TextFormField(
                  controller: _participantsController,
                  decoration: const InputDecoration(
                    labelText: 'Participants (comma separated)',
                    hintText: 'e.g. Zied, Ahmed, Sara',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter at least one participant';
                    }
                    return null;
                  },
                  maxLines: 2,
                ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isSaving ? null : _saveExpense,
                child: Text(
                  _isSaving
                      ? 'Saving...'
                      : _isEditing
                      ? 'Save expense'
                      : 'Add expense',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
