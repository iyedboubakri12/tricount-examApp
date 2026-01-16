import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_state.dart';
import '../providers/groups_provider.dart';
import 'groups_screen.dart';
import 'group_details_screen.dart';
import 'expense_form_screen.dart';
import '../widgets/labeled_fab.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  void _openAddExpense() {
    final groupsProvider = context.read<GroupsProvider>();
    final appState = context.read<AppState>();
    final selectedGroupId = appState.selectedGroupId;
    final selectedGroup = selectedGroupId == null
        ? null
        : groupsProvider.getById(selectedGroupId);

    if (groupsProvider.groups.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Create a group first')));
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ExpenseFormScreen(group: selectedGroup),
      ),
    );
  }

  void _onOpenGroup(String groupId) {
    context.read<AppState>().selectedGroupId = groupId;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => GroupDetailsScreen(groupId: groupId)),
    );
  }

  void _ensureSelectedGroup(GroupsProvider groupsProvider, AppState appState) {
    final groups = groupsProvider.groups;
    if (groups.isEmpty) {
      if (appState.selectedGroupId != null) {
        // Clear selection when the last group is removed.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          appState.selectedGroupId = null;
        });
      }
      return;
    }

    final exists = groups.any((group) => group.id == appState.selectedGroupId);
    if (!exists) {
      // If a group was deleted, fall back to the first one.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        appState.selectedGroupId = groups.first.id;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupsProvider = context.watch<GroupsProvider>();
    final appState = context.watch<AppState>();
    _ensureSelectedGroup(groupsProvider, appState);

    return Scaffold(
      body: GroupsScreen(onOpenGroup: _onOpenGroup),
      floatingActionButton: LabeledFab(
        label: 'Add Expense',
        icon: Icons.add,
        onPressed: _openAddExpense,
        heroTag: 'add_expense_fab',
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
