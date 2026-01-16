import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/group.dart';
import '../models/member.dart';
import '../providers/expenses_provider.dart';
import '../providers/groups_provider.dart';

class MembersScreen extends StatelessWidget {
  final String groupId;

  const MembersScreen({super.key, required this.groupId});

  String _newId(String prefix) {
    return '${prefix}_${DateTime.now().microsecondsSinceEpoch}';
  }

  Future<void> _showMemberSheet(
    BuildContext context,
    Group group, {
    Member? member,
  }) async {
    final controller = TextEditingController(text: member?.name ?? '');

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                member == null ? 'Add member' : 'Rename member',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'Member name',
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  final name = controller.text.trim();
                  if (name.isEmpty) {
                    return;
                  }

                  final members = [...group.members];
                  if (member == null) {
                    members.add(Member(id: _newId('m'), name: name));
                  } else {
                    final index = members.indexWhere((m) => m.id == member.id);
                    if (index != -1) {
                      members[index] = Member(id: member.id, name: name);
                    }
                  }

                  final updated = Group(
                    id: group.id,
                    name: group.name,
                    members: members,
                  );
                  context.read<GroupsProvider>().updateGroup(updated);
                  Navigator.of(context).pop();
                },
                child: Text(member == null ? 'Add' : 'Save'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _removeMember(
    BuildContext context,
    Group group,
    Member member,
  ) async {
    final expenses = context.read<ExpensesProvider>().expenses;
    final used = expenses.any(
      (expense) =>
          expense.payerMemberId == member.id ||
          expense.participantIds.contains(member.id),
    );

    if (used) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot remove member used in expenses.'),
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove member?'),
        content: Text('Remove ${member.name} from this group?'),
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

    final members = group.members.where((m) => m.id != member.id).toList();
    final updated = Group(id: group.id, name: group.name, members: members);
    await context.read<GroupsProvider>().updateGroup(updated);
  }

  @override
  Widget build(BuildContext context) {
    final group = context.watch<GroupsProvider>().getById(groupId);
    if (group == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Members')),
        body: const Center(child: Text('Group not found.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Members'),
        actions: [
          IconButton(
            onPressed: () => _showMemberSheet(context, group),
            icon: const Icon(Icons.person_add_alt_1),
            tooltip: 'Add member',
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: group.members.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final member = group.members[index];
          return Card(
            child: ListTile(
              title: Text(member.name),
              trailing: PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'rename') {
                    _showMemberSheet(context, group, member: member);
                  }
                  if (value == 'remove') {
                    _removeMember(context, group, member);
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'rename', child: Text('Rename')),
                  PopupMenuItem(value: 'remove', child: Text('Remove')),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showMemberSheet(context, group),
        child: const Icon(Icons.add),
      ),
    );
  }
}
