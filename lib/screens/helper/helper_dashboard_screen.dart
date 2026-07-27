import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';

import 'earnings_screen.dart';

// main helper navigation screen container
class HelperMainMainScreen extends StatelessWidget {
  const HelperMainMainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<CareDropAppState>();

    final List<Widget> pages = [
      const HelperDashboardView(), // Index 0: Home
      const Center(child: Text('Tasks Screen Coming Soon')), // Index 1: Tasks
      const EarningsScreen(), // Index 2: Earnings
      const Center(child: Text('Profile Screen Coming Soon')), // Index 3: Profile
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
          selectedItemColor: CareDropTheme.tealPrimary,
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
              color: CareDropTheme.tealPrimary,
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
                      // Notification icon button popup trigger
                      GestureDetector(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Notifications Triggered!'),
                              duration: Duration(seconds: 2),
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

                  // Online switch container
                  GestureDetector(
                    onTap: () => appState.toggleOnlineAvailability(),
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
                                Text(
                                  user.isOnline
                                      ? 'Visible to task requests'
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
                            onChanged: (val) =>
                                appState.toggleOnlineAvailability(),
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
                          valueColor: CareDropTheme.tealPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Completed tasks count stat box
                    Expanded(
                      child: _StatBox(
                        value: '${user.totalTasksCompleted}',
                        label: 'Tasks',
                        valueColor: CareDropTheme.tealPrimary,
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
                  if (activeTask != null) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: CareDropTheme.tealPrimary,
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
                                    color: CareDropTheme.tealPrimary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Text(
                                'Started ${activeTask.startTimeStr}',
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
                            '${activeTask.hospital} · ${activeTask.patientInfo}',
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
                                    backgroundColor: CareDropTheme.tealPrimary,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                    ),
                                  ),
                                  // Popup trigger message for view task
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('View Task Triggered!'),
                                        duration: Duration(seconds: 2),
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
                                  // Popup trigger message for navigation
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Navigate Triggered!'),
                                        duration: Duration(seconds: 2),
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
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('See All Tasks Triggered!'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        child: const Text(
                          'See All',
                          style: TextStyle(
                            fontSize: 12,
                            color: CareDropTheme.tealPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  // List of available nearby tasks
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: appState.availableTasks.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final task = appState.availableTasks[index];
                      // Task item tile
                      return _DashboardTaskTile(
                        task: task,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Task Clicked: ${task.title}'),
                              duration: const Duration(seconds: 2),
                            ),
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

// Individual task list tile item
class _DashboardTaskTile extends StatelessWidget {
  final dynamic task;
  final VoidCallback onTap;

  const _DashboardTaskTile({required this.task, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: CareDropTheme.cardBorderColor),
        ),
        child: Row(
          children: [
            // Task icon
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFE6F4F1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.medical_services_outlined,
                color: CareDropTheme.tealPrimary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            // Task title and distance
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: CareDropTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${task.distanceStr}',
                    style: const TextStyle(
                      color: CareDropTheme.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            // Task price and urgent badge
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${task.currency} ${task.price.toInt()}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: CareDropTheme.tealPrimary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                // Task urgency badge tag
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: task.isUrgent
                        ? CareDropTheme.urgentBg
                        : CareDropTheme.normalBg,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    task.isUrgent ? 'Urgent' : 'Normal',
                    style: TextStyle(
                      color: task.isUrgent
                          ? CareDropTheme.urgentText
                          : CareDropTheme.normalText,
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


