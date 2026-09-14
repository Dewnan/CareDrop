import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../common/edit_profile_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<CareDropAppState>();

    return Scaffold(
      backgroundColor: CareDropTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Settings',
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
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            // Section 0: ACCOUNT & PROFILE
            const Text(
              'ACCOUNT & PROFILE',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: CareDropTheme.textMuted,
                fontSize: 11,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),

            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: CareDropTheme.cardBorderColor),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                leading: const Icon(Icons.person_outline, color: CareDropTheme.royalBlue),
                title: const Text(
                  'Edit Profile Details',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: CareDropTheme.textPrimary,
                  ),
                ),
                subtitle: const Text(
                  'Update profile picture, name, phone, and details',
                  style: TextStyle(fontSize: 12, color: CareDropTheme.textMuted),
                ),
                trailing: const Icon(Icons.chevron_right, size: 20, color: CareDropTheme.textMuted),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const EditProfileScreen(),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 24),
            // Section 1: NOTIFICATIONS
            const Text(
              'NOTIFICATIONS',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: CareDropTheme.textMuted,
                fontSize: 11,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),

            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: CareDropTheme.cardBorderColor),
              ),
              child: Column(
                children: [
                  _SwitchTile(
                    title: 'Task Alerts',
                    value: appState.taskAlerts,
                    onChanged: (v) => appState.toggleTaskAlerts(v),
                  ),
                  const Divider(color: CareDropTheme.cardBorderColor, height: 1),
                  _SwitchTile(
                    title: 'Payment Updates',
                    value: appState.paymentUpdates,
                    onChanged: (v) => appState.togglePaymentUpdates(v),
                  ),
                  const Divider(color: CareDropTheme.cardBorderColor, height: 1),
                  _SwitchTile(
                    title: 'Promotions',
                    value: appState.promotions,
                    onChanged: (v) => appState.togglePromotions(v),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Section 2: WORK
            const Text(
              'WORK',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: CareDropTheme.textMuted,
                fontSize: 11,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),

            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: CareDropTheme.cardBorderColor),
              ),
              child: Column(
                children: [
                  _SwitchTile(
                    title: 'Auto-Accept Tasks',
                    value: appState.autoAcceptTasks,
                    onChanged: (v) => appState.toggleAutoAcceptTasks(v),
                  ),
                  const Divider(color: CareDropTheme.cardBorderColor, height: 1),
                  _SwitchTile(
                    title: 'Show on Map',
                    value: appState.showOnMap,
                    onChanged: (v) => appState.toggleShowOnMap(v),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: CareDropTheme.textPrimary,
        ),
      ),
      trailing: Switch(
        value: value,
        activeThumbColor: Colors.white,
        activeTrackColor: CareDropTheme.royalBlue,
        onChanged: onChanged,
      ),
    );
  }
}
