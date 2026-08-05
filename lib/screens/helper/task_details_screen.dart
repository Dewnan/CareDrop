import 'package:flutter/material.dart';
import '../../models/task_model.dart';
import '../../theme/app_theme.dart';
import 'task_accept_screen.dart';

class TaskDetailsScreen extends StatelessWidget {
  final TaskModel task;

  const TaskDetailsScreen({
    super.key,
    required this.task,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CareDropTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Task Details',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: IconButton(
            icon: const Icon(Icons.chevron_left, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Main Task Summary Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: CareDropTheme.cardBorderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            task.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: CareDropTheme.textPrimary,
                            ),
                          ),
                        ),
                        Text(
                          '${task.currency} ${task.price.toInt()}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: CareDropTheme.tealPrimary,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Urgent badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: task.isUrgent ? CareDropTheme.urgentBg : CareDropTheme.normalBg,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        task.isUrgent ? 'Urgent' : 'Normal',
                        style: TextStyle(
                          color: task.isUrgent ? CareDropTheme.urgentText : CareDropTheme.normalText,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                    const Divider(color: CareDropTheme.cardBorderColor, height: 1),
                    const SizedBox(height: 16),

                    _DetailItem(label: 'Location', value: task.locationDetail),
                    const SizedBox(height: 12),
                    _DetailItem(label: 'Deadline', value: task.deadline),
                    const SizedBox(height: 12),
                    _DetailItem(label: 'Patient', value: task.patientInfo),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Description Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: CareDropTheme.cardBorderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: CareDropTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      task.description,
                      style: const TextStyle(
                        fontSize: 13,
                        color: CareDropTheme.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Accept Task Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CareDropTheme.tealPrimary,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TaskAcceptScreen(task: task),
                      ),
                    );
                  },
                  child: Text(
                    'Accept Task — RM ${(task.price / 10).toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  final String label;
  final String value;

  const _DetailItem({required this.label, required this.value});

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
          value,
          style: const TextStyle(
            color: CareDropTheme.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
