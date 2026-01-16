import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/expense.dart';
import '../models/group.dart';
import '../models/member.dart';
import '../providers/expenses_provider.dart';
import '../providers/exchange_rate_provider.dart';
import '../providers/groups_provider.dart';
import '../utils/formatters.dart';

class ExpenseFormScreen extends StatefulWidget {
  final Group? group;
  final Expense? existingExpense;

  const ExpenseFormScreen({super.key, this.group, this.existingExpense});

  @override
  State<ExpenseFormScreen> createState() => _ExpenseFormScreenState();
}

class _ExpenseFormScreenState extends State<ExpenseFormScreen> {
  static int _seed = 0;

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  late DateTime _date;
  String? _payerId;
  late Set<String> _participantIds;
  late List<Member> _allMembers;
  Group? _selectedGroup;
  double? _convertedUsd;
  bool _isSaving = false;
  bool _isConverting = false;

  bool get _isEditing => widget.existingExpense != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingExpense;
    _date = existing?.date ?? DateTime.now();
    _selectedGroup = widget.group;
    _allMembers = _selectedGroup != null
        ? List.from(_selectedGroup!.members)
        : [];
    _payerId =
        existing?.payerMemberId ??
        (_selectedGroup != null && _selectedGroup!.members.isNotEmpty
            ? _selectedGroup!.members.first.id
            : null);
    _participantIds =
        existing?.participantIds.toSet() ??
        (_selectedGroup != null
            ? _selectedGroup!.members.map((m) => m.id).toSet()
            : {});
    _convertedUsd = existing?.convertedAmountUsd;
    _titleController.text = existing?.title ?? '';
    if (existing != null) {
      _amountController.text = existing.amountEur.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
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

    final rate = await context.read<ExchangeRateProvider>().fetchRate();

    if (!mounted) {
      return;
    }

    setState(() {
      _isConverting = false;
    });

    if (rate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not fetch rate, try again')),
      );
      return;
    }

    setState(() {
      _convertedUsd = amount * rate;
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

  void _onGroupChanged(Group? group) {
    if (group == null) return;

    setState(() {
      _selectedGroup = group;
      _allMembers = List.from(group.members);
      _participantIds = group.members.map((m) => m.id).toSet();
      _payerId = group.members.isNotEmpty ? group.members.first.id : null;
    });
  }

  Future<void> _addNewParticipant() async {
    if (_selectedGroup == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a group first')),
      );
      return;
    }

    final controller = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Add Participant'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Participant name',
            hintText: 'Enter name',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (!mounted) {
      controller.dispose();
      return;
    }

    if (result == true && controller.text.trim().isNotEmpty) {
      final newMember = Member(id: _newId('m'), name: controller.text.trim());
      setState(() {
        _allMembers.add(newMember);
        _participantIds.add(newMember.id);
      });
    }
    controller.dispose();
  }

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedGroup == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a group')));
      return;
    }

    if (_payerId == null) {
      return;
    }

    if (_participantIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one participant')),
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

    // Check if new members were added and update the group
    final newMembers = _allMembers
        .where(
          (member) => !_selectedGroup!.members.any((m) => m.id == member.id),
        )
        .toList();

    if (newMembers.isNotEmpty) {
      final updatedGroup = Group(
        id: _selectedGroup!.id,
        name: _selectedGroup!.name,
        members: [..._selectedGroup!.members, ...newMembers],
      );
      await context.read<GroupsProvider>().updateGroup(updatedGroup);
    }

    final expense = Expense(
      id: widget.existingExpense?.id ?? _newId('e'),
      groupId: _selectedGroup!.id,
      title: _titleController.text.trim(),
      amountEur: amount,
      payerMemberId: _payerId!,
      participantIds: _participantIds.toList(),
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
    final allGroups = context.watch<GroupsProvider>().groups;

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Expense' : 'New Expense')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _isEditing
                    ? 'Update the expense details.'
                    : 'Create a new expense.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              if (!_isEditing && allGroups.isNotEmpty)
                DropdownButtonFormField<Group>(
                  value: _selectedGroup,
                  decoration: const InputDecoration(
                    labelText: 'Group',
                    prefixIcon: Icon(Icons.group),
                  ),
                  items: allGroups
                      .map(
                        (group) => DropdownMenuItem(
                          value: group,
                          child: Text(group.name),
                        ),
                      )
                      .toList(),
                  onChanged: _onGroupChanged,
                  validator: (value) {
                    if (value == null) {
                      return 'Please select a group';
                    }
                    return null;
                  },
                ),
              if (!_isEditing && allGroups.isNotEmpty)
                const SizedBox(height: 16),
              if (allGroups.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'No groups available. Please create a group first.',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              if (allGroups.isEmpty) const SizedBox(height: 16),
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
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: _clearRateCache,
                  child: const Text('Clear cached rate'),
                ),
              ),
              const SizedBox(height: 16),
              if (_selectedGroup != null)
                DropdownButtonFormField<String>(
                  value: _payerId,
                  decoration: const InputDecoration(labelText: 'Payer'),
                  items: _allMembers
                      .map(
                        (member) => DropdownMenuItem(
                          value: member.id,
                          child: Text(member.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _payerId = value;
                    });
                  },
                ),
              if (_selectedGroup != null) const SizedBox(height: 16),
              Card(
                child: ListTile(
                  title: const Text('Date'),
                  subtitle: Text(formatDate(_date)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: _pickDate,
                ),
              ),
              const SizedBox(height: 16),
              if (_selectedGroup != null)
                Text(
                  'Participants',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              if (_selectedGroup != null) const SizedBox(height: 8),
              if (_selectedGroup != null)
                Card(
                  child: Column(
                    children: [
                      ..._allMembers
                          .map(
                            (member) => CheckboxListTile(
                              value: _participantIds.contains(member.id),
                              title: Text(member.name),
                              onChanged: (selected) {
                                setState(() {
                                  if (selected == true) {
                                    _participantIds.add(member.id);
                                  } else {
                                    _participantIds.remove(member.id);
                                  }
                                });
                              },
                            ),
                          )
                          .toList(),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: OutlinedButton.icon(
                          onPressed: _selectedGroup != null
                              ? _addNewParticipant
                              : null,
                          icon: const Icon(Icons.person_add),
                          label: const Text('Add participant'),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isSaving ? null : _saveExpense,
                child: Text(
                  _isSaving
                      ? 'Saving...'
                      : _isEditing
                      ? 'Save changes'
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
