class Payment {
  final String id;
  final String groupId;
  final String fromMemberId;
  final String toMemberId;
  final double amountEur;
  final DateTime date;

  const Payment({
    required this.id,
    required this.groupId,
    required this.fromMemberId,
    required this.toMemberId,
    required this.amountEur,
    required this.date,
  });
}
