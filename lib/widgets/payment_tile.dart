import 'package:flutter/material.dart';

class PaymentTile extends StatelessWidget {
  final String from;
  final String to;
  final String amountText;
  final String dateText;
  final VoidCallback? onDelete;

  const PaymentTile({
    super.key,
    required this.from,
    required this.to,
    required this.amountText,
    required this.dateText,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text('$from paid $to'),
        subtitle: Text(dateText),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              amountText,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            if (onDelete != null) ...[
              const SizedBox(width: 8),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Delete payment',
              ),
            ],
          ],
        ),
      ),
    );
  }
}
