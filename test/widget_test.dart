import 'package:flutter_test/flutter_test.dart';

import 'package:tricount/models/expense.dart';
import 'package:tricount/models/member.dart';
import 'package:tricount/utils/split_calculator.dart';

void main() {
  test('balances split evenly and settle', () {
    final alice = Member(id: 'a', name: 'Alice');
    final bob = Member(id: 'b', name: 'Bob');

    final expense = Expense(
      id: 'e1',
      groupId: 'g1',
      title: 'Dinner',
      amountEur: 10,
      payerMemberId: alice.id,
      participantIds: [alice.id, bob.id],
      date: DateTime(2024, 1, 1),
    );

    final balances = calculateBalances([alice, bob], [expense]);
    final aliceBalance = balances.firstWhere((b) => b.member.id == alice.id);
    final bobBalance = balances.firstWhere((b) => b.member.id == bob.id);

    expect(aliceBalance.amount, 5);
    expect(bobBalance.amount, -5);

    final settlements = calculateSettlements(balances);
    expect(settlements.length, 1);
    expect(settlements.first.from.id, bob.id);
    expect(settlements.first.to.id, alice.id);
    expect(settlements.first.amount, 5);
  });
}
