import 'package:hive/hive.dart';

import '../models/payment.dart';

class PaymentRepository {
  Box<Payment> get _box => Hive.box<Payment>('payments');

  List<Payment> forGroup(String groupId) {
    final payments = _box.values.where((p) => p.groupId == groupId).toList();
    payments.sort((a, b) => b.date.compareTo(a.date));
    return payments;
  }

  Future<void> put(Payment payment) async {
    await _box.put(payment.id, payment);
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  Future<void> clear() async {
    await _box.clear();
  }
}
