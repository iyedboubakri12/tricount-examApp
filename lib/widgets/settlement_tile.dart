import 'package:flutter/material.dart';

class SettlementTile extends StatelessWidget {
  final String from;
  final String to;
  final String amountText;
  final VoidCallback? onMarkPaid;

  const SettlementTile({
    super.key,
    required this.from,
    required this.to,
    required this.amountText,
    this.onMarkPaid,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text('$from pays $to'),
        trailing: onMarkPaid == null
            ? Text(
                amountText,
                style: Theme.of(context).textTheme.titleSmall,
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    amountText,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: onMarkPaid,
                    icon: const Icon(Icons.check_circle),
                    tooltip: 'Mark as paid',
                  ),
                ],
              ),
      ),
    );
  }
}
