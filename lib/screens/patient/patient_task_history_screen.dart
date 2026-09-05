import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/task_model.dart';
import '../../providers/app_state.dart';
import '../../services/task_service.dart';
import '../../services/user_profile_service.dart';
import '../../theme/app_theme.dart';

/// Renders the patient's real task history fetched dynamically from Firestore.
class PatientTaskHistoryScreen extends StatelessWidget {
  const PatientTaskHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<CareDropAppState>();
    final patientId = appState.currentUserModel?.id ?? '';

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
      body: patientId.isEmpty
          ? const Center(
              child: Text(
                'No user signed in.',
                style: TextStyle(color: CareDropTheme.textMuted),
              ),
            )
          : StreamBuilder<List<TaskModel>>(
              stream: TaskService.streamPatientTasks(patientId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final tasks = snapshot.data ?? [];

                if (tasks.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history, size: 64, color: Colors.grey),
                        SizedBox(height: 12),
                        Text(
                          'No task history available yet.',
                          style: TextStyle(color: CareDropTheme.textMuted, fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: tasks.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {

                    final task = tasks[index];
                    final isCompleted = task.progressStep == TaskProgressStep.completed;
                    final isCancelled = task.progressStep == TaskProgressStep.cancelled;

                    Color tagBg = const Color(0xFFFEF3C7);
                    Color tagTextColor = const Color(0xFFD97706);
                    String statusText = 'In Progress';

                    if (isCompleted) {
                      tagBg = const Color(0xFFDCFCE7);
                      tagTextColor = const Color(0xFF16A34A);
                      statusText = 'Done';
                    } else if (isCancelled) {
                      tagBg = const Color(0xFFFEE2E2);
                      tagTextColor = const Color(0xFFDC2626);
                      statusText = 'Cancelled';
                    } else if (task.progressStep == TaskProgressStep.pending) {
                      statusText = 'Pending';
                    }

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
                              color: tagBg,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              isCompleted
                                  ? Icons.check_circle_outline
                                  : isCancelled
                                      ? Icons.cancel_outlined
                                      : Icons.pending_actions,
                              color: tagTextColor,
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
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: CareDropTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${task.hospital} · ${task.deadline}',
                                  style: const TextStyle(color: CareDropTheme.textMuted, fontSize: 12),
                                ),
                                 if (task.assignedHelperId != null && task.assignedHelperId!.isNotEmpty) ...[
                                   const SizedBox(height: 2),
                                   FutureBuilder(
                                     future: UserProfileService.getUserProfile(task.assignedHelperId!),
                                     builder: (context, helperSnapshot) {
                                       final helperName = helperSnapshot.data?.fullName;
                                       final displayText = (helperName != null && helperName.isNotEmpty)
                                           ? helperName
                                           : task.assignedHelperId!;
                                       return Text(
                                         'Helper: $displayText',
                                         style: const TextStyle(color: CareDropTheme.textSecondary, fontSize: 12),
                                       );
                                     },
                                   ),
                                 ],
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${task.currency} ${task.price.toStringAsFixed(2)}',
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
                                  color: tagBg,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  statusText,
                                  style: TextStyle(
                                    color: tagTextColor,
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
                );
              },
            ),
    );
  }
}

