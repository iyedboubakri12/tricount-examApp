import 'package:flutter/foundation.dart';

import '../data/expense_repository.dart';
import '../models/expense.dart';

class ExpensesProvider extends ChangeNotifier {
  ExpensesProvider({required ExpenseRepository expenseRepo})
      : _repo = expenseRepo;

  final ExpenseRepository _repo;
  String? _groupId;
  List<Expense> _expenses = [];
  bool _isLoading = false;

  List<Expense> get expenses => _expenses;
  bool get isLoading => _isLoading;

  // Used for the home stats when no group is selected.
  List<Expense> getAllExpenses() {
    return _repo.getAll();
  }

  void setGroupId(String? groupId) {
    if (_groupId == groupId) {
      return;
    }
    _groupId = groupId;
    _load();
  }

  Future<void> _load() async {
    _isLoading = true;
    notifyListeners();
    if (_groupId == null) {
      _expenses = [];
    } else {
      _expenses = _repo.forGroup(_groupId!);
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addExpense(Expense expense) async {
    await _repo.put(expense);
    if (_groupId == expense.groupId) {
      _expenses = _repo.forGroup(_groupId!);
      notifyListeners();
    }
  }

  Future<void> deleteExpense(String id) async {
    await _repo.delete(id);
    if (_groupId != null) {
      _expenses = _repo.forGroup(_groupId!);
      notifyListeners();
    }
  }

  Future<void> deleteExpensesForGroup(String groupId) async {
    await _repo.deleteByGroup(groupId);
    if (_groupId == groupId) {
      _expenses = [];
      notifyListeners();
    }
  }

  Future<void> clearAll() async {
    await _repo.clear();
    _expenses = [];
    notifyListeners();
  }
}
