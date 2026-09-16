import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../theme/app_theme.dart';

/// Reusable modular task card component used across Patient Dashboard, Patient Task History,
/// Helper Dashboard, and Helper Task Browse screens.
class TaskCardTile extends StatelessWidget {
  final TaskModel task;
  final VoidCallback? onTap;

  const TaskCardTile({
    super.key,
    required this.task,
    this.onTap,
  });

  /// Selects an appropriate category icon based on task category.
  IconData _getCategoryIcon(TaskCategory category) {
    switch (category) {
      case TaskCategory.medicine:
        return Icons.medication_outlined;
      case TaskCategory.delivery:
        return Icons.local_shipping_outlined;
      case TaskCategory.queue:
        return Icons.access_time_rounded;
      case TaskCategory.urgent:
        return Icons.priority_high_rounded;
      case TaskCategory.filing:
      case TaskCategory.all:
        return Icons.inventory_2_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDone = task.progressStep == TaskProgressStep.completed;
    final isCancelled = task.progressStep == TaskProgressStep.cancelled;

    String statusLabel = 'In Progress';
    Color tagBg = CareDropTheme.pendingBg;
    Color tagTextColor = CareDropTheme.pendingText;

    if (isDone) {
      statusLabel = 'Done';
      tagBg = CareDropTheme.paidBg;
      tagTextColor = CareDropTheme.paidText;
    } else if (isCancelled) {
      statusLabel = 'Cancelled';
      tagBg = CareDropTheme.urgentBg;
      tagTextColor = CareDropTheme.urgentText;
    } else if (task.progressStep == TaskProgressStep.pending) {
      statusLabel = 'Pending';
    }

    final subtitleText = task.pickupAddress.replaceAll('(select via map)', '').trim();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: CareDropTheme.cardBorderColor),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: task.isUrgent ? CareDropTheme.urgentBg : CareDropTheme.normalBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _getCategoryIcon(task.category),
                color: task.isUrgent ? CareDropTheme.urgentText : CareDropTheme.royalBlue,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: CareDropTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitleText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: CareDropTheme.textMuted,
                      fontSize: 12,
                    ),
                  ),

                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${task.currency} ${task.price.toInt()}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: CareDropTheme.royalBlue,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: tagBg,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      color: tagTextColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
