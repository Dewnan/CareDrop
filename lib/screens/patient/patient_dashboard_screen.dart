import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../components/feedback_banner.dart';
import '../../components/loading_indicator.dart';
import '../../components/notification_tile.dart';
import '../../components/task_card_tile.dart';
import '../../models/notification_model.dart';
import '../../models/task_model.dart';
import '../../providers/app_state.dart';
import '../../services/notification_service.dart';
import '../../services/task_service.dart';
import '../../theme/app_theme.dart';
import 'patient_create_task_form_screen.dart';
import 'patient_matched_helper_screen.dart';
import 'patient_searching_helpers_screen.dart';
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
                  ],
                ),
                const SizedBox(height: 20),

                // Active Task Card inside header
                if (activeTask != null)
                  InkWell(
                    onTap: () {
                      if (activeTask.assignedHelperId != null || activeTask.progressStep != TaskProgressStep.pending) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PatientMatchedHelperScreen(taskId: activeTask.id),
                          ),
                        );
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PatientSearchingHelpersScreen(taskId: activeTask.id),
                          ),
                        );
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              Text(
                                'Active Task',
                                style: TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                              Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white70),
                            ],
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
                            '${activeTask.pickupAddress} · ${activeTask.deadline}',
                            style: const TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                        ],
                      ),
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
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: TaskCardTile(
                                  task: t,

                                  onTap: () {
                                    if (t.assignedHelperId != null || t.progressStep != TaskProgressStep.pending) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => PatientMatchedHelperScreen(taskId: t.id),
                                        ),
                                      );
                                    } else {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => PatientSearchingHelpersScreen(taskId: t.id),
                                        ),
                                      );
                                    }
                                  },
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
                      ? 'Queue Assistance'
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
}

/// Renders the patient alerts/notifications tab with persistent past notifications, local caching,
/// NotificationTile widgets, swipe-to-dismiss, and a Clear All option.
class _PatientAlertsTab extends StatefulWidget {
  const _PatientAlertsTab();

  @override
  State<_PatientAlertsTab> createState() => _PatientAlertsTabState();
}

class _PatientAlertsTabState extends State<_PatientAlertsTab> {
  List<NotificationModel> _cachedNotifications = [];

  @override
  void initState() {
    super.initState();
    _loadInitialCache();
  }

  /// Loads cached notifications from SharedPreferences before Firestore stream emits.
  Future<void> _loadInitialCache() async {
    final userId = context.read<CareDropAppState>().currentUserModel?.id ?? '';
    if (userId.isNotEmpty) {
      final cached = await NotificationService.getCachedNotifications(userId);
      if (mounted && cached.isNotEmpty) {
        setState(() {
          _cachedNotifications = cached;
        });
      }
    }
  }

  /// Displays confirmation dialog before clearing all notifications.
  void _confirmClearAll(BuildContext context, String userId) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Clear All Notifications?'),
        content: const Text('This will remove all notification records permanently.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              await NotificationService.clearAllNotifications(userId);
              if (context.mounted) {
                FeedbackBanner.show(
                  context,
                  message: 'All notifications cleared',
                  type: FeedbackType.success,
                );
              }
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<CareDropAppState>();
    final userId = appState.currentUserModel?.id ?? '';

    return Scaffold(
      backgroundColor: CareDropTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Notifications & Alerts'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (userId.isNotEmpty)
            TextButton(
              onPressed: () => _confirmClearAll(context, userId),
              child: const Text(
                'Clear All',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),
      body: userId.isEmpty
          ? const Center(
              child: Text(
                'Please sign in to view notifications.',
                style: TextStyle(color: CareDropTheme.textMuted),
              ),
            )
          : StreamBuilder<List<NotificationModel>>(
              stream: NotificationService.streamNotifications(userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && _cachedNotifications.isEmpty) {
                  return const Center(
                    child: AppLoadingIndicator(color: CareDropTheme.royalBlue, size: 24),
                  );
                }

                final notifications = snapshot.data ?? _cachedNotifications;

                if (notifications.isEmpty) {
                  return const Center(
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
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: notifications.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = notifications[index];
                    return NotificationTile(
                      notification: item,
                      onDismiss: () => NotificationService.deleteNotification(userId, item.id),
                    );
                  },
                );
              },
            ),
    );
  }
}

