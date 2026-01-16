import 'package:flutter/material.dart';

class BalanceTile extends StatelessWidget {
  final String name;
  final String amountText;
  final bool isPositive;

  const BalanceTile({
    super.key,
    required this.name,
    required this.amountText,
    required this.isPositive,
  });

  @override
  Widget build(BuildContext context) {
    final color = isPositive
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.error;

    return Card(
      child: ListTile(
        title: Text(name),
        trailing: Text(
          amountText,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: color,
              ),
        ),
      ),
    );
  }
}
