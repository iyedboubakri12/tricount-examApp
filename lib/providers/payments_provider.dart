import 'package:flutter/foundation.dart';

import '../data/payment_repository.dart';
import '../models/payment.dart';

class PaymentsProvider extends ChangeNotifier {
  PaymentsProvider(this._repo);

  final PaymentRepository _repo;
  String? _groupId;
  List<Payment> _payments = [];
  bool _isLoading = false;

  List<Payment> get payments => _payments;
  bool get isLoading => _isLoading;

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
      _payments = [];
    } else {
      _payments = _repo.forGroup(_groupId!);
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addPayment(Payment payment) async {
    await _repo.put(payment);
    if (_groupId == payment.groupId) {
      _payments = _repo.forGroup(_groupId!);
      notifyListeners();
    }
  }

  Future<void> deletePayment(String id) async {
    await _repo.delete(id);
    if (_groupId != null) {
      _payments = _repo.forGroup(_groupId!);
      notifyListeners();
    }
  }

  Future<void> clearAll() async {
    await _repo.clear();
    _payments = [];
    notifyListeners();
  }
}
