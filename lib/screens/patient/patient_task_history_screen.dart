import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../components/task_card_tile.dart';
import '../../models/task_model.dart';
import '../../providers/app_state.dart';
import '../../services/task_service.dart';
import '../../theme/app_theme.dart';
import '../helper/task_details_screen.dart';
import 'patient_matched_helper_screen.dart';

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
                    return TaskCardTile(
                      task: task,
                      showDistance: false,
                      onTap: () {
                        if (task.assignedHelperId != null || task.progressStep != TaskProgressStep.pending) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PatientMatchedHelperScreen(taskId: task.id),
                            ),
                          );
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TaskDetailsScreen(task: task),
                            ),
                          );
                        }
                      },
                    );
                  },
                );
              },
            ),
    );
  }
}


