class ActivityLog {
  final String id;
  final String groupId;
  final String title;
  final String message;
  final DateTime createdAt;

  const ActivityLog({
    required this.id,
    required this.groupId,
    required this.title,
    required this.message,
    required this.createdAt,
  });
}
