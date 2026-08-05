import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class PatientTaskHistoryScreen extends StatelessWidget {
  const PatientTaskHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final historyTasks = [
      {
        'title': 'Medication Pickup',
        'location': 'PPUM KL',
        'date': 'Today, 9:30 AM',
        'helper': 'Ahmad Razif',
        'status': 'Active',
        'amount': 'RS 180.00',
        'isCompleted': false,
      },
      {
        'title': 'Document Submission',
        'location': 'HKL KL',
        'date': 'Yesterday, 2:15 PM',
        'helper': 'Siti Nur',
        'status': 'Done',
        'amount': 'RS 120.00',
        'isCompleted': true,
      },
      {
        'title': 'Pharmacy Run',
        'location': 'Hospital Ampang',
        'date': '3 days ago',
        'helper': 'Muhammad Ali',
        'status': 'Done',
        'amount': 'RS 150.00',
        'isCompleted': true,
      },
      {
        'title': 'Patient Escort',
        'location': 'Kuala Lumpur Clinic',
        'date': '1 week ago',
        'helper': 'Fatimah Binti',
        'status': 'Done',
        'amount': 'RS 220.00',
        'isCompleted': true,
      },
    ];

    return Scaffold(
      backgroundColor: CareDropTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Task History',
          style: TextStyle(
            color: CareDropTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: historyTasks.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final task = historyTasks[index];
          final isCompleted = task['isCompleted'] as bool;

          return Container(
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
                    color: isCompleted ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isCompleted ? Icons.check_circle_outline : Icons.pending_actions,
                    color: isCompleted ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task['title'] as String,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: CareDropTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${task['location']} · ${task['date']}',
                        style: const TextStyle(color: CareDropTheme.textMuted, fontSize: 12),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Helper: ${task['helper']}',
                        style: const TextStyle(color: CareDropTheme.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      task['amount'] as String,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: CareDropTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isCompleted ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        task['status'] as String,
                        style: TextStyle(
                          color: isCompleted ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
