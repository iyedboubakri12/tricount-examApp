import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/group.dart';
import '../models/member.dart';
import '../providers/app_state.dart';
import '../providers/groups_provider.dart';

class GroupFormScreen extends StatefulWidget {
  final Group? existingGroup;

  const GroupFormScreen({super.key, this.existingGroup});

  @override
  State<GroupFormScreen> createState() => _GroupFormScreenState();
}

class _GroupFormScreenState extends State<GroupFormScreen> {
  static int _seed = 0;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final List<_MemberField> _memberFields = [];
  bool _isSaving = false;

  bool get _isEditing => widget.existingGroup != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingGroup;
    if (existing != null) {
      _nameController.text = existing.name;
      for (final member in existing.members) {
        // Keep the same member id so existing expenses still point to them.
        _memberFields.add(
          _MemberField(
            id: member.id,
            controller: TextEditingController(text: member.name),
          ),
        );
      }
    }

    if (_memberFields.length < 2) {
      final missing = 2 - _memberFields.length;
      for (var i = 0; i < missing; i++) {
        _memberFields.add(
          _MemberField(id: _newId('m'), controller: TextEditingController()),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    for (final field in _memberFields) {
      field.controller.dispose();
    }
    super.dispose();
  }

  String _newId(String prefix) {
    _seed += 1;
    return '${prefix}_${DateTime.now().microsecondsSinceEpoch}_$_seed';
  }

  void _addMemberField() {
    setState(() {
      _memberFields.add(
        _MemberField(id: _newId('m'), controller: TextEditingController()),
      );
    });
  }

  void _removeMemberField(int index) {
    if (_memberFields.length <= 2) {
      return;
    }
    setState(() {
      final field = _memberFields.removeAt(index);
      field.controller.dispose();
    });
  }

  Future<void> _saveGroup() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final names = _memberFields
        .map((field) => field.controller.text.trim())
        .where((name) => name.isNotEmpty)
        .toList();

    if (names.length < 2) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Add at least two members')));
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final groupId = widget.existingGroup?.id ?? _newId('g');
    final members = <Member>[];
    for (final field in _memberFields) {
      final name = field.controller.text.trim();
      if (name.isEmpty) {
        continue;
      }
      members.add(Member(id: field.id, name: name));
    }

    final group = Group(
      id: groupId,
      name: _nameController.text.trim(),
      members: members,
    );

    final groupsProvider = context.read<GroupsProvider>();
    if (_isEditing) {
      await groupsProvider.updateGroup(group);
    } else {
      await groupsProvider.addGroup(group);
      context.read<AppState>().selectedGroupId = groupId;
    }
    // Activity log removed

    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Group' : 'New Group')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _isEditing
                    ? 'Update the group details and member names.'
                    : 'Create a group and list its members.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Group name'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a group name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Text('Members', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              ..._memberFields.asMap().entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: entry.value.controller,
                          decoration: InputDecoration(
                            labelText: 'Member ${entry.key + 1}',
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Enter a name';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (_memberFields.length > 2)
                        IconButton(
                          onPressed: () => _removeMemberField(entry.key),
                          icon: const Icon(Icons.close),
                        ),
                    ],
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: _addMemberField,
                icon: const Icon(Icons.person_add_alt_1),
                label: const Text('Add member'),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isSaving ? null : _saveGroup,
                child: Text(
                  _isSaving
                      ? 'Saving...'
                      : _isEditing
                      ? 'Save changes'
                      : 'Create group',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MemberField {
  final String id;
  final TextEditingController controller;

  _MemberField({required this.id, required this.controller});
}
