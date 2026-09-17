import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Reusable layout component to display a label-value pair in task summary cards
class TaskDetailRow extends StatelessWidget {
  final String label;
  final String value;

  const TaskDetailRow({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: const TextStyle(
              color: CareDropTheme.textMuted,
              fontSize: 12,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: CareDropTheme.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
