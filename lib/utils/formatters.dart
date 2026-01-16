import 'package:intl/intl.dart';

final _eur = NumberFormat.currency(symbol: 'EUR ', decimalDigits: 2);
final _usd = NumberFormat.currency(symbol: 'USD ', decimalDigits: 2);
final _date = DateFormat('d MMM yyyy');
final _dateTime = DateFormat('d MMM yyyy HH:mm');

String formatEur(double value) => _eur.format(value);

String formatUsd(double value) => _usd.format(value);

String formatDate(DateTime value) => _date.format(value);

String formatDateTime(DateTime value) => _dateTime.format(value);
