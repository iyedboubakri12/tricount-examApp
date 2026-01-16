import 'package:hive/hive.dart';

import '../models/expense.dart';

class ExpenseRepository {
  Box<Expense> get _box => Hive.box<Expense>('expenses');

  List<Expense> forGroup(String groupId) {
    final expenses = _box.values.where((e) => e.groupId == groupId).toList();
    expenses.sort((a, b) => b.date.compareTo(a.date));
    return expenses;
  }

  List<Expense> getAll() {
    final expenses = _box.values.toList();
    expenses.sort((a, b) => b.date.compareTo(a.date));
    return expenses;
  }

  Future<void> put(Expense expense) async {
    await _box.put(expense.id, expense);
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  Future<void> deleteByGroup(String groupId) async {
    final entries = _box.toMap().entries.toList();
    for (final entry in entries) {
      if (entry.value.groupId == groupId) {
        await _box.delete(entry.key);
      }
    }
  }

  Future<void> clear() async {
    await _box.clear();
  }
}
