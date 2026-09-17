import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Reusable component for displaying price/fee breakdown rows in summary cards
class TaskPriceRow extends StatelessWidget {
  final String label;
  final String price;

  const TaskPriceRow({
    super.key,
    required this.label,
    required this.price,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: CareDropTheme.textMuted,
            fontSize: 13,
          ),
        ),
        Text(
          price,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: CareDropTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}
