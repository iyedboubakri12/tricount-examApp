import 'package:flutter/material.dart';

class AppState extends ChangeNotifier {
  String? _selectedGroupId;

  String? get selectedGroupId => _selectedGroupId;

  set selectedGroupId(String? value) {
    if (_selectedGroupId == value) {
      return;
    }
    _selectedGroupId = value;
    notifyListeners();
  }
}
