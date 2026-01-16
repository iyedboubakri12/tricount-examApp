import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../data/exchange_rate_repository.dart';
import '../models/exchange_rate.dart';

class ExchangeRateProvider extends ChangeNotifier {
  ExchangeRateProvider(this._repo);

  final ExchangeRateRepository _repo;
  ExchangeRate? _cached;
  bool _isLoading = false;

  ExchangeRate? get cachedRate => _cached;
  bool get isLoading => _isLoading;

  Future<void> loadCached() async {
    _cached = _repo.getLatest();
    notifyListeners();
  }

  Future<double?> fetchRate() async {
    final cached = _repo.getLatest();
    if (cached != null) {
      final age = DateTime.now().difference(cached.fetchedAt);
      // Reuse cached rate for 12 hours to avoid extra network calls.
      if (age < const Duration(hours: 12)) {
        _cached = cached;
        return cached.rate;
      }
    }

    _isLoading = true;
    notifyListeners();
    try {
      // Simple HTTP call to get the latest EUR -> USD rate.
      final response = await http.get(
        Uri.parse('https://api.frankfurter.app/latest?from=EUR&to=USD'),
      ).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) {
        return null;
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final rates = data['rates'] as Map<String, dynamic>;
      final usdValue = rates['USD'];
      if (usdValue == null) {
        return null;
      }
      final rate = (usdValue as num).toDouble();
      final saved = ExchangeRate(rate: rate, fetchedAt: DateTime.now());
      await _repo.saveLatest(saved);
      _cached = saved;
      return rate;
    } catch (_) {
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> clearCached() async {
    await _repo.clearLatest();
    _cached = null;
    notifyListeners();
  }
}
