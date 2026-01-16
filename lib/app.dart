import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/exchange_rate_repository.dart';
import 'data/expense_repository.dart';
import 'data/group_repository.dart';
import 'data/payment_repository.dart';
import 'providers/app_state.dart';
import 'providers/exchange_rate_provider.dart';
import 'providers/expenses_provider.dart';
import 'providers/groups_provider.dart';
import 'providers/payments_provider.dart';
import 'screens/home_shell.dart';
import 'theme/app_theme.dart';

class TricountApp extends StatelessWidget {
  const TricountApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Data repositories - handle reading/writing to Hive database
        Provider(create: (_) => GroupRepository()),
        Provider(create: (_) => ExpenseRepository()),
        Provider(create: (_) => ExchangeRateRepository()),
        Provider(create: (_) => PaymentRepository()),
        // ActivityLog removed

        // Global app state (which group is selected)
        ChangeNotifierProvider(create: (_) => AppState()),

        // Groups provider - loads and manages all groups
        ChangeNotifierProvider(
          create: (context) {
            final provider = GroupsProvider(context.read<GroupRepository>());
            provider.loadGroups();
            return provider;
          },
        ),

        // Expenses provider - filters expenses by selected group
        ChangeNotifierProxyProvider2<
          AppState,
          ExpenseRepository,
          ExpensesProvider
        >(
          create: (context) =>
              ExpensesProvider(expenseRepo: context.read<ExpenseRepository>()),
          update: (context, appState, repo, previous) {
            final provider = previous ?? ExpensesProvider(expenseRepo: repo);
            // Update expenses whenever the selected group changes
            provider.setGroupId(appState.selectedGroupId);
            return provider;
          },
        ),

        // Payments provider - filters payments by selected group
        ChangeNotifierProxyProvider2<
          AppState,
          PaymentRepository,
          PaymentsProvider
        >(
          create: (context) =>
              PaymentsProvider(context.read<PaymentRepository>()),
          update: (context, appState, repo, previous) {
            final provider = previous ?? PaymentsProvider(repo);
            provider.setGroupId(appState.selectedGroupId);
            return provider;
          },
        ),

        // ActivityLog removed

        // Exchange rate provider - caches currency conversion rates
        ChangeNotifierProvider(
          create: (context) {
            final provider = ExchangeRateProvider(
              context.read<ExchangeRateRepository>(),
            );
            provider.loadCached();
            return provider;
          },
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'tricount',
        theme: AppTheme.buildLight(),
        home: const HomeShell(),
      ),
    );
  }
}
