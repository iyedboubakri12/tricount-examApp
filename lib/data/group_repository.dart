import 'package:hive/hive.dart';

import '../models/group.dart';

class GroupRepository {
  Box<Group> get _box => Hive.box<Group>('groups');

  List<Group> getAll() {
    final groups = _box.values.toList();
    groups.sort((a, b) => a.name.compareTo(b.name));
    return groups;
  }

  Future<void> put(Group group) async {
    await _box.put(group.id, group);
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  Future<void> clear() async {
    await _box.clear();
  }
}
