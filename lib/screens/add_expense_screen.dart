import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/expense.dart';
import '../models/group.dart';
import '../models/member.dart';
import '../providers/expenses_provider.dart';
import '../providers/exchange_rate_provider.dart';
import '../providers/groups_provider.dart';
import '../utils/formatters.dart';

class AddExpenseScreen extends StatefulWidget {
  final Group group;

  const AddExpenseScreen({super.key, required this.group});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  static int _seed = 0;

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _newParticipantController = TextEditingController();
  late DateTime _date;
  String? _payerId;
  late Set<String> _participantIds;
  late Set<String> _lastSyncedMemberIds;
  double? _convertedUsd;
  bool _isSaving = false;
  bool _isConverting = false;

  @override
  void initState() {
    super.initState();
    _date = DateTime.now();
    _payerId = widget.group.members.isNotEmpty
        ? widget.group.members.first.id
        : null;
    _participantIds = widget.group.members.map((m) => m.id).toSet();
    _lastSyncedMemberIds = {..._participantIds};
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _newParticipantController.dispose();
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

  Future<void> _addNewParticipant() async {
    final name = _newParticipantController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a participant name')),
      );
      return;
    }

    final groupsProvider = context.read<GroupsProvider>();
    final currentGroup =
        groupsProvider.getById(widget.group.id) ?? widget.group;

    // Check if name already exists
    final exists = currentGroup.members.any(
      (member) => member.name.toLowerCase() == name.toLowerCase(),
    );
    if (exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Participant already exists')),
      );
      return;
    }

    // Create new member
    final newMember = Member(id: _newId('m'), name: name);

    // Update group with new member
    final updatedGroup = Group(
      id: widget.group.id,
      name: widget.group.name,
      members: [...currentGroup.members, newMember],
    );

    try {
      setState(() {
        _participantIds = {..._participantIds, newMember.id};
        _payerId ??= newMember.id;
        _lastSyncedMemberIds = updatedGroup.members.map((m) => m.id).toSet();
      });
      await context.read<GroupsProvider>().updateGroup(updatedGroup);
      _newParticipantController.clear();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Participant added')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error adding participant: $e')));
      }
    }
  }

  void _syncWithGroup(Group group) {
    final memberIds = group.members.map((m) => m.id).toSet();
    if (setEquals(memberIds, _lastSyncedMemberIds)) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _participantIds.retainAll(memberIds);
        if (_participantIds.isEmpty) {
          _participantIds = {...memberIds};
        }

        if (_payerId == null || !memberIds.contains(_payerId)) {
          _payerId = group.members.isNotEmpty ? group.members.first.id : null;
        }

        _lastSyncedMemberIds = memberIds;
      });
    });
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

    final expense = Expense(
      id: _newId('e'),
      groupId: widget.group.id,
      title: _titleController.text.trim(),
      amountEur: amount,
      payerMemberId: _payerId!,
      participantIds: _participantIds.toList(),
      date: _date,
      convertedAmountUsd: _convertedUsd,
    );

    await context.read<ExpensesProvider>().addExpense(expense);

    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  void didUpdateWidget(covariant AddExpenseScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Check if group members have changed (by count or content)
    final oldMemberIds = oldWidget.group.members.map((m) => m.id).toSet();
    final newMemberIds = widget.group.members.map((m) => m.id).toSet();

    if (oldMemberIds != newMemberIds) {
      setState(() {
        // Update participants to include only members that still exist
        _participantIds.retainAll(newMemberIds);

        // If no participants selected, select all new members
        if (_participantIds.isEmpty) {
          _participantIds = newMemberIds;
        }

        // If payer no longer exists, select first member
        if (!newMemberIds.contains(_payerId)) {
          _payerId = widget.group.members.isNotEmpty
              ? widget.group.members.first.id
              : null;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupsProvider = context.watch<GroupsProvider>();
    final group = groupsProvider.getById(widget.group.id) ?? widget.group;

    _syncWithGroup(group);

    return Scaffold(
      appBar: AppBar(title: const Text('New Expense')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Add an expense for ${group.name}.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
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
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _payerId,
                decoration: const InputDecoration(labelText: 'Payer'),
                items: group.members
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
              Card(
                child: Column(
                  children: [
                    ...group.members
                        .map(
                          (member) => CheckboxListTile(
                            key: ValueKey(member.id),
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
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _newParticipantController,
                              decoration: InputDecoration(
                                hintText: 'Add new participant',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                              onSubmitted: (_) => _addNewParticipant(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: _addNewParticipant,
                            icon: const Icon(Icons.add),
                            label: const Text('Add'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: _isSaving ? null : _saveExpense,
                child: Text(_isSaving ? 'Saving...' : 'Add expense'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
