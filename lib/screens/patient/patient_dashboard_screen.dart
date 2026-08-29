import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/task_model.dart';
import '../../providers/app_state.dart';
import '../../services/task_service.dart';
import '../../theme/app_theme.dart';
import 'patient_create_task_form_screen.dart';
import 'patient_task_history_screen.dart';
import 'patient_profile_screen.dart';


class PatientDashboardScreen extends StatefulWidget {
  const PatientDashboardScreen({super.key});

  @override
  State<PatientDashboardScreen> createState() => _PatientDashboardScreenState();
}

class _PatientDashboardScreenState extends State<PatientDashboardScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CareDropTheme.backgroundColor,
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          _PatientHomeTab(),
          PatientTaskHistoryScreen(),
          _PatientAlertsTab(),
          PatientProfileScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: CareDropTheme.black,
        unselectedItemColor: CareDropTheme.textMuted,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Tasks'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications_outlined), activeIcon: Icon(Icons.notifications), label: 'Alerts'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class _PatientHomeTab extends StatelessWidget {
  const _PatientHomeTab();

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<CareDropAppState>();
    final activeTask = appState.activeTask;

    return SingleChildScrollView(

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Blue Banner
          Container(
            color: CareDropTheme.royalBlue,
            padding: const EdgeInsets.fromLTRB(20, 56, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Hello,',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          appState.currentUserModel?.fullName ?? 'Patient User',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [

                        IconButton(
                          icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Active Task Card inside header
                if (activeTask != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Active Task',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          activeTask.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${activeTask.hospital} · ${activeTask.deadline}',
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Create New Task Callout Banner
                InkWell(
                  onTap: () {
                    // Navigate directly to task creation form
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PatientCreateTaskFormScreen()),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 240, 241, 242),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: CareDropTheme.royalBlue,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.add, color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Create New Task',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Get help within minutes',
                                style: TextStyle(color: Colors.black45, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios, color: Colors.black45, size: 16),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // QUICK ACTIONS
                const Text(
                  'QUICK ACTIONS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: CareDropTheme.textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildQuickAction(context, 'Pickup', Icons.inventory_2_outlined, const Color(0xFFEFF6FF), CareDropTheme.royalBlue),
                    const SizedBox(width: 10),
                    _buildQuickAction(context, 'Delivery', Icons.local_shipping_outlined, const Color(0xFFECFDF5), const Color(0xFF10B981)),
                    const SizedBox(width: 10),
                    _buildQuickAction(context, 'Escort', Icons.access_time, const Color(0xFFF5F3FF), const Color(0xFF8B5CF6)),
                    const SizedBox(width: 10),
                    _buildQuickAction(context, 'Docs', Icons.description_outlined, const Color(0xFFFEF3C7), const Color(0xFFF59E0B)),
                  ],
                ),

                const SizedBox(height: 28),

                // RECENT TASKS
                const Text(
                  'RECENT TASKS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: CareDropTheme.textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),

                appState.currentUserModel?.id == null
                    ? const Text(
                        'No recent tasks.',
                        style: TextStyle(color: CareDropTheme.textMuted, fontSize: 13),
                      )
                    : StreamBuilder<List<TaskModel>>(
                        stream: TaskService.streamPatientTasks(appState.currentUserModel!.id),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }

                          final patientTasks = snapshot.data ?? [];

                          if (patientTasks.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Text(
                                'No recent tasks created yet.',
                                style: TextStyle(color: CareDropTheme.textMuted, fontSize: 13),
                              ),
                            );
                          }

                          return Column(
                            children: patientTasks.map((t) {
                              final isDone = t.progressStep == TaskProgressStep.completed;
                              final isCancelled = t.progressStep == TaskProgressStep.cancelled;

                              String statusLabel = 'Active';
                              Color bg = const Color(0xFFFEF3C7);
                              Color textCol = const Color(0xFFD97706);

                              if (isDone) {
                                statusLabel = 'Done';
                                bg = const Color(0xFFDCFCE7);
                                textCol = const Color(0xFF16A34A);
                              } else if (isCancelled) {
                                statusLabel = 'Cancelled';
                                bg = const Color(0xFFFEE2E2);
                                textCol = const Color(0xFFDC2626);
                              } else if (t.progressStep == TaskProgressStep.pending) {
                                statusLabel = 'Pending';
                              }

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _buildRecentTaskItem(
                                  t.title,
                                  '${t.hospital} · ${t.deadline}',
                                  statusLabel,
                                  bg,
                                  textCol,
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildQuickAction(BuildContext context, String title, IconData icon, Color bgColor, Color iconColor) {
    return Expanded(
      child: InkWell(
        onTap: () {
          // Map quick action title to initial task type name
          final String initialType = title == 'Pickup'
              ? 'Medicine Pickup'
              : title == 'Delivery'
                  ? 'Document Delivery'
                  : title == 'Escort'
                      ? 'Queue/Token Assistance'
                      : 'Pharmacy Purchase';

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PatientCreateTaskFormScreen(initialTaskType: initialType),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: CareDropTheme.cardBorderColor),
          ),
          child: Column(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: CareDropTheme.textPrimary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentTaskItem(String title, String subtitle, String status, Color tagBg, Color tagTextColor) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CareDropTheme.cardBorderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.inventory_2_outlined, color: CareDropTheme.tealPrimary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: CareDropTheme.textPrimary)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(color: CareDropTheme.textMuted, fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: tagBg, borderRadius: BorderRadius.circular(6)),
            child: Text(
              status,
              style: TextStyle(color: tagTextColor, fontWeight: FontWeight.bold, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}

/// Renders the patient alerts/notifications tab with an empty state when no alerts exist.
class _PatientAlertsTab extends StatelessWidget {
  const _PatientAlertsTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications & Alerts'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_none_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 12),
            Text(
              'No notifications or alerts yet.',
              style: TextStyle(color: CareDropTheme.textMuted, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

