import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/group.dart';
import '../providers/app_state.dart';
import '../providers/groups_provider.dart';

Future<void> showGroupFormSheet(BuildContext context, {Group? existingGroup}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => GroupFormSheet(existingGroup: existingGroup),
  );
}

class GroupFormSheet extends StatefulWidget {
  final Group? existingGroup;

  const GroupFormSheet({super.key, this.existingGroup});

  @override
  State<GroupFormSheet> createState() => _GroupFormSheetState();
}

class _GroupFormSheetState extends State<GroupFormSheet> {
  static int _seed = 0;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _isSaving = false;

  bool get _isEditing => widget.existingGroup != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingGroup;
    if (existing != null) {
      _nameController.text = existing.name;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String _newId(String prefix) {
    _seed += 1;
    return '${prefix}_${DateTime.now().microsecondsSinceEpoch}_$_seed';
  }

  Future<void> _saveGroup() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final groupId = widget.existingGroup?.id ?? _newId('g');
    final members = widget.existingGroup?.members ?? [];

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
                _isEditing ? 'Edit tricount' : 'Add tricount',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'E.g. City Trip',
                  prefixIcon: Icon(Icons.beach_access_outlined),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isSaving ? null : _saveGroup,
                child: Text(
                  _isSaving
                      ? 'Saving...'
                      : _isEditing
                      ? 'Save tricount'
                      : 'Create tricount',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
