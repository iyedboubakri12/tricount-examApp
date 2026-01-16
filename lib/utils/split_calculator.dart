import 'dart:math';

import '../models/expense.dart';
import '../models/member.dart';
import '../models/payment.dart';

/// Shows how much money each person owes or is owed
class BalanceEntry {
  final Member member;
  final double amount; // Positive = they should receive, Negative = they owe

  const BalanceEntry({required this.member, required this.amount});
}

/// A payment transaction: "Alice pays Bob 10 EUR"
class Settlement {
  final Member from; // Who pays
  final Member to; // Who receives
  final double amount; // How much

  const Settlement({
    required this.from,
    required this.to,
    required this.amount,
  });
}

/// Calculate who owes whom
/// Example: Alice paid 30 EUR for pizza shared with Bob
/// Alice is owed 15 EUR from Bob
List<BalanceEntry> calculateBalances(
  List<Member> members,
  List<Expense> expenses, [
  List<Payment> payments = const [],
]) {
  // Start: everyone has 0 balance
  final balances = <String, double>{
    for (final member in members) member.id: 0.0,
  };

  // Process each expense
  for (final expense in expenses) {
    // Skip planned/future expenses
    if (expense.isPlanned) {
      continue;
    }

    // Who should split this cost?
    final people = expense.participantIds.toSet();
    people.add(expense.payerMemberId); // Include payer even if not in list

    if (people.isEmpty) continue;

    // Calculate each person's fair share
    final share = expense.amountEur / people.length;

    // Each participant now owes their share
    for (final personId in people) {
      if (balances.containsKey(personId)) {
        balances[personId] = balances[personId]! - share;
      }
    }

    // The payer already paid the full amount, so add it back
    // (They paid for everyone, so they get the money back)
    if (balances.containsKey(expense.payerMemberId)) {
      balances[expense.payerMemberId] =
          balances[expense.payerMemberId]! + expense.amountEur;
    }
  }

  // Process any manual payments already made
  for (final payment in payments) {
    if (balances.containsKey(payment.fromMemberId)) {
      balances[payment.fromMemberId] =
          balances[payment.fromMemberId]! + payment.amountEur;
    }
    if (balances.containsKey(payment.toMemberId)) {
      balances[payment.toMemberId] =
          balances[payment.toMemberId]! - payment.amountEur;
    }
  }

  // Convert to BalanceEntry objects
  return members
      .map(
        (member) => BalanceEntry(
          member: member,
          amount: _round2(balances[member.id] ?? 0),
        ),
      )
      .toList();
}

/// Calculate the minimum payments to settle all debts
/// Example: Alice owes 10, Bob owes 5, Carol is owed 15
/// → Alice pays Carol 10, Bob pays Carol 5
List<Settlement> calculateSettlements(List<BalanceEntry> balances) {
  // Separate creditors (owed money) from debtors (owe money)
  final creditors =
      balances
          .where((entry) => entry.amount > 0.01) // Owed money
          .map((entry) => _Bucket(member: entry.member, amount: entry.amount))
          .toList()
        ..sort((a, b) => b.amount.compareTo(a.amount)); // Largest first

  final debtors =
      balances
          .where((entry) => entry.amount < -0.01) // Owes money
          .map((entry) => _Bucket(member: entry.member, amount: -entry.amount))
          .toList()
        ..sort((a, b) => b.amount.compareTo(a.amount)); // Largest first

  // Match debtors with creditors to create minimum settlements
  final settlements = <Settlement>[];
  var debtorIndex = 0;
  var creditorIndex = 0;

  while (debtorIndex < debtors.length && creditorIndex < creditors.length) {
    final debtor = debtors[debtorIndex];
    final creditor = creditors[creditorIndex];

    // Payment is limited by the smaller amount
    final paymentAmount = min(debtor.amount, creditor.amount);

    // Create settlement
    settlements.add(
      Settlement(
        from: debtor.member,
        to: creditor.member,
        amount: _round2(paymentAmount),
      ),
    );

    // Reduce both amounts
    debtor.amount -= paymentAmount;
    creditor.amount -= paymentAmount;

    // Move to next debtor/creditor if this one is settled
    if (debtor.amount <= 0.01) {
      debtorIndex++;
    }
    if (creditor.amount <= 0.01) {
      creditorIndex++;
    }
  }

  return settlements;
}

/// Helper class to track money in/out
class _Bucket {
  final Member member;
  double amount;

  _Bucket({required this.member, required this.amount});
}

/// Round to 2 decimal places (cents)
double _round2(double value) {
  return (value * 100).roundToDouble() / 100;
}
