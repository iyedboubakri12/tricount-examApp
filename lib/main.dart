import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'data/hive_adapters.dart';
import 'models/expense.dart';
import 'models/exchange_rate.dart';
import 'models/group.dart';
import 'models/payment.dart';

/// Main entry point of the app
/// Sets up Hive database before running the app
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive (local database)
  await Hive.initFlutter();

  // Register custom objects so Hive can save them
  registerHiveAdapters();

  // Create Hive "boxes" (like tables) for each data type
  await Hive.openBox<Group>('groups'); // Stores group data
  await Hive.openBox<Expense>('expenses'); // Stores all expenses
  await Hive.openBox<ExchangeRate>('exchange_rate'); // Caches currency rates
  await Hive.openBox<Payment>('payments'); // Tracks who paid who
  await Hive.openBox('settings'); // App settings (dark mode, etc)

  // Start the app
  runApp(const TricountApp());
}
