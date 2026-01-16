import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/group.dart';
import '../models/member.dart';
import '../providers/app_state.dart';
import '../providers/groups_provider.dart';

class AddGroupScreen extends StatefulWidget {
  const AddGroupScreen({super.key});

  @override
  State<AddGroupScreen> createState() => _AddGroupScreenState();
}

class _AddGroupScreenState extends State<AddGroupScreen> {
  static int _seed = 0;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _membersController = TextEditingController();
  bool _isSaving = false;

  String _newId(String prefix) {
    _seed += 1;
    return '${prefix}_${DateTime.now().microsecondsSinceEpoch}_$_seed';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _membersController.dispose();
    super.dispose();
  }

  Future<void> _saveGroup() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final memberNames = _membersController.text
        .split(',')
        .map((name) => name.trim())
        .where((name) => name.isNotEmpty)
        .toList();

    setState(() {
      _isSaving = true;
    });

    final groupId = _newId('g');
    final members = memberNames
        .map((name) => Member(id: _newId('m'), name: name))
        .toList();

    final group = Group(id: groupId, name: _nameController.text.trim(), members: members);

    await context.read<GroupsProvider>().addGroup(group);
    context.read<AppState>().selectedGroupId = groupId;

    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Group'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Create a group and list its members.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Group name',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a group name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _membersController,
                decoration: const InputDecoration(
                  labelText: 'Members (comma separated)',
                  hintText: 'Alice, Bruno, Carla',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please add at least two members';
                  }
                  final names = value
                      .split(',')
                      .map((name) => name.trim())
                      .where((name) => name.isNotEmpty)
                      .toList();
                  if (names.length < 2) {
                    return 'Add at least two members';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isSaving ? null : _saveGroup,
                child: Text(_isSaving ? 'Saving...' : 'Create group'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
