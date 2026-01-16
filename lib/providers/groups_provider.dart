import 'package:flutter/foundation.dart';

import '../data/group_repository.dart';
import '../models/group.dart';

/// Manages all groups in the app
/// When data changes, notifyListeners() tells all screens to update
class GroupsProvider extends ChangeNotifier {
  GroupsProvider(this._repo);

  final GroupRepository _repo; // Read/write data to Hive
  List<Group> _groups = []; // List of all groups
  bool _isLoading = false; // Is data loading?

  List<Group> get groups => _groups;
  bool get isLoading => _isLoading;

  /// Load all groups from Hive database
  Future<void> loadGroups() async {
    _isLoading = true;
    notifyListeners(); // Tell UI we're loading

    _groups = _repo.getAll(); // Get from Hive

    _isLoading = false;
    notifyListeners(); // Tell UI we're done loading
  }

  /// Add a new group
  Future<void> addGroup(Group group) async {
    await _repo.put(group); // Save to Hive
    _groups = _repo.getAll(); // Reload list
    notifyListeners(); // Update UI
  }

  /// Update an existing group
  Future<void> updateGroup(Group group) async {
    await _repo.put(group);
    _groups = _repo.getAll();
    notifyListeners();
  }

  /// Delete a group
  Future<void> deleteGroup(String id) async {
    await _repo.delete(id);
    _groups = _repo.getAll();
    notifyListeners();
  }

  /// Clear all groups (for reset)
  Future<void> clearAll() async {
    await _repo.clear();
    _groups = [];
    notifyListeners();
  }

  /// Find a group by its ID
  Group? getById(String id) {
    for (final group in _groups) {
      if (group.id == id) {
        return group;
      }
    }
    return null;
  }
}
