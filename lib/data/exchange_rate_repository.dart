import 'package:hive/hive.dart';

import '../models/exchange_rate.dart';

class ExchangeRateRepository {
  Box<ExchangeRate> get _box => Hive.box<ExchangeRate>('exchange_rate');

  ExchangeRate? getLatest() {
    return _box.get('latest');
  }

  Future<void> saveLatest(ExchangeRate rate) async {
    await _box.put('latest', rate);
  }

  Future<void> clearLatest() async {
    await _box.delete('latest');
  }
}
