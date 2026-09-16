import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../components/offline_task_placeholder.dart';
import '../../components/task_card_tile.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import 'helper_notifications_screen.dart';

import '../../models/task_model.dart';
import '../../services/task_service.dart';
import 'task_browse_screen.dart';
import 'task_details_screen.dart';
import 'helper_map_screen.dart';
import 'earnings_screen.dart';
import 'profile_screen.dart';

// main helper navigation screen container
class HelperMainMainScreen extends StatelessWidget {
  const HelperMainMainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<CareDropAppState>();

    final List<Widget> pages = [
      const HelperDashboardView(), // Index 0: Home
      const TaskBrowseScreen(),    // Index 1: Tasks
      const EarningsScreen(),      // Index 2: Earnings
      const ProfileScreen(),       // Index 3: Profile
    ];

    // Bottom Navigation Bar
    return Scaffold(
      body: pages[appState.currentTab], // Displays screen according to selected tab
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: CareDropTheme.cardBorderColor, width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: appState.currentTab,
          onTap: (index) => appState.setTab(index),
          backgroundColor: Colors.white,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: CareDropTheme.black,
          unselectedItemColor: CareDropTheme.textMuted,
          selectedLabelStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          items: const [
            // Home tab
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            // Tasks tab
            BottomNavigationBarItem(
              icon: Icon(Icons.search_rounded),
              activeIcon: Icon(Icons.search_rounded),
              label: 'Tasks',
            ),
            // Earnings tab
            BottomNavigationBarItem(
              icon: Icon(Icons.attach_money_rounded),
              activeIcon: Icon(Icons.attach_money_rounded),
              label: 'Earnings',
            ),
            // Profile tab
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

// Main container for helper dashboard view
class HelperDashboardView extends StatelessWidget {
  const HelperDashboardView({super.key});

  // Builds the main helper dashboard view showing online status, summary statistics, active task info, and live nearby pending tasks
  @override
  Widget build(BuildContext context) {
    final appState = context.watch<CareDropAppState>();
    final user = appState.helperUser;
    final activeTask = appState.activeTask;

    return Scaffold(
      backgroundColor: CareDropTheme.backgroundColor,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Teal Header Box
            Container(
              width: double.infinity,
              color: CareDropTheme.royalBlue,
              padding: const EdgeInsets.fromLTRB(20, 52, 20, 36),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User greeting header & notification button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Hello,',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            user.fullName.split(' ').first,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      // Notification button trigger
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const HelperNotificationsScreen(),
                            ),
                          );
                        },
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.notifications_none_rounded,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Online switch container & Rank Tier Badge
                  GestureDetector(
                    onTap: () => appState.setOnlineAvailability(!appState.helperUser.isOnline),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          // Online status indicator dot
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: user.isOnline
                                  ? const Color(0xFF22C55E)
                                  : Colors.grey,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user.isOnline
                                      ? 'You are Online'
                                      : 'You are Offline',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  user.isOnline
                                      ? 'You will receive nearby task'
                                      : 'Hidden from new tasks',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Toggle switch for online/offline
                          Switch(
                            value: user.isOnline,
                            activeThumbColor: Colors.white,
                            activeTrackColor: const Color(0xFF10B981),
                            onChanged: (_) =>
                                appState.setOnlineAvailability(!appState.helperUser.isOnline),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 3 Stat Cards floating over bottom of header
            Transform.translate(
              offset: const Offset(0, -20),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    // Today earnings stat box (tap to view earnings screen)
                    Expanded(
                      child: GestureDetector(
                        onTap: () => appState.setTab(2),
                        child: _StatBox(
                          value: 'Rs.${user.todayEarnings.toInt()}',
                          label: 'Today',
                          valueColor: CareDropTheme.royalBlue,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Completed tasks count stat box
                    Expanded(
                      child: _StatBox(
                        value: '${user.totalTasksCompleted}',
                        label: 'Tasks',
                        valueColor: CareDropTheme.royalBlue,
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Helper rating stat box
                    Expanded(
                      child: _StatBox(
                        value: '${user.rating}★',
                        label: 'Rating',
                        valueColor: const Color(0xFFF59E0B),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Active task card if present
                  if (activeTask != null && activeTask.progressStep != TaskProgressStep.completed) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: CareDropTheme.royalBlue,
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDCFCE7),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'Active Task',
                                  style: TextStyle(
                                    color: CareDropTheme.royalBlue,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Text(
                                'Due: ${activeTask.deadline}',
                                style: const TextStyle(
                                  color: CareDropTheme.textMuted,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            activeTask.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: CareDropTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            activeTask.pickupAddress,
                            style: const TextStyle(
                              fontSize: 13,
                              color: CareDropTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: CareDropTheme.royalBlue,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                    ),
                                  ),
                                  // Open task status screen for active task
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => TaskDetailsScreen(task: activeTask),
                                      ),
                                    );
                                  },
                                  child: const Text(
                                    'View Task',
                                    style: TextStyle(fontSize: 13),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                    ),
                                  ),
                                  // Open helper map navigation screen
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => HelperMapScreen(task: activeTask),
                                      ),
                                    );
                                  },
                                  child: const Text(
                                    'Navigate',
                                    style: TextStyle(fontSize: 13),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // NEARBY TASKS header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'NEARBY TASKS',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: CareDropTheme.textSecondary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      // See all tasks button trigger
                      TextButton(
                        onPressed: () => appState.setTab(1),
                        child: const Text(
                          'See All',
                          style: TextStyle(
                            fontSize: 12,
                            color: CareDropTheme.royalBlue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  // List of available nearby tasks streamed dynamically from TaskService
                  if (!user.isOnline)
                    const OfflineTaskPlaceholder()
                  else
                    StreamBuilder<List<TaskModel>>(
                      stream: TaskService.streamPendingTasks(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }

                        final tasks = snapshot.data ?? [];

                        if (tasks.isEmpty) {
                          return Container(
                            padding: const EdgeInsets.all(20),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: CareDropTheme.cardBorderColor),
                            ),
                            child: const Text(
                              'No nearby tasks available right now.',
                              style: TextStyle(
                                fontSize: 13,
                                color: CareDropTheme.textMuted,
                              ),
                            ),
                          );
                        }

                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: tasks.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final task = tasks[index];
                          return TaskCardTile(
                            task: task,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => TaskDetailsScreen(task: task),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Helper stat box widget
class _StatBox extends StatelessWidget {
  final String value;
  final String label;
  final Color valueColor;

  const _StatBox({
    required this.value,
    required this.label,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CareDropTheme.cardBorderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: CareDropTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}




