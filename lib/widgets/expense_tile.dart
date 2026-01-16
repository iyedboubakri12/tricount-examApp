import 'package:flutter/material.dart';

import '../models/expense.dart';

class ExpenseTile extends StatelessWidget {
  final Expense expense;
  final String payerName;
  final String amountText;
  final String dateText;
  final String? convertedText;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  const ExpenseTile({
    super.key,
    required this.expense,
    required this.payerName,
    required this.amountText,
    required this.dateText,
    this.convertedText,
    this.onEdit,
    this.onDelete,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        title: Text(expense.title),
        subtitle: Text('Paid by $payerName - $dateText'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  amountText,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                if (convertedText != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    convertedText!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
            if (onEdit != null || onDelete != null) ...[
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    onEdit?.call();
                  }
                  if (value == 'delete') {
                    onDelete?.call();
                  }
                },
                itemBuilder: (context) {
                  final items = <PopupMenuEntry<String>>[];
                  if (onEdit != null) {
                    items.add(
                      const PopupMenuItem(
                        value: 'edit',
                        child: Text('Edit'),
                      ),
                    );
                  }
                  if (onDelete != null) {
                    items.add(
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete'),
                      ),
                    );
                  }
                  return items;
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
