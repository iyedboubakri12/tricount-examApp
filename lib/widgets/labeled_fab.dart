import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class LabeledFab extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final String heroTag;

  const LabeledFab({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    required this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    final primarySoft = AppColors.primarySoft;
    final primary = Theme.of(context).colorScheme.primary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton(
          heroTag: heroTag,
          onPressed: onPressed,
          child: Icon(icon, size: 30),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: primarySoft,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
