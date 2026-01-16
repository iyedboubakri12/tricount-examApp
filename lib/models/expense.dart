/// Represents a shared expense in a group
/// Example: "Pizza - 30 EUR paid by Alice, shared by Alice and Bob"
class Expense {
  final String id; // Unique identifier
  final String groupId; // Which group this expense belongs to
  final String title; // What was bought (e.g., "Pizza")
  final double amountEur; // Amount in EUR
  final String payerMemberId; // Who paid
  final List<String> participantIds; // Who should pay their share
  final DateTime date; // When it was paid
  final double? convertedAmountUsd; // Optional USD conversion
  final bool isPlanned; // Is it a planned expense or already settled

  const Expense({
    required this.id,
    required this.groupId,
    required this.title,
    required this.amountEur,
    required this.payerMemberId,
    required this.participantIds,
    required this.date,
    this.convertedAmountUsd,
    this.isPlanned = false,
  });
}
