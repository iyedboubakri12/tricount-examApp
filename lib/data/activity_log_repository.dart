import 'package:hive/hive.dart';

import '../models/activity_log.dart';

class ActivityLogRepository {
  Box<ActivityLog> get _box => Hive.box<ActivityLog>('activity_logs');

  List<ActivityLog> forGroup(String groupId) {
    final logs = _box.values.where((log) => log.groupId == groupId).toList();
    logs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return logs;
  }

  Future<void> put(ActivityLog log) async {
    await _box.put(log.id, log);
  }

  Future<void> clear() async {
    await _box.clear();
  }
}
