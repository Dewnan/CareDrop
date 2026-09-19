import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../components/user_avatar_widget.dart';
import '../common/edit_profile_screen.dart';
import '../common/help_center_screen.dart';
import '../common/landing_screen.dart';
import 'settings_screen.dart';
import 'ratings_screen.dart';
import 'payout_settings_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<CareDropAppState>();
    final user = appState.helperUser;

    return Scaffold(
      backgroundColor: CareDropTheme.backgroundColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top Teal Profile Card Banner
            Container(
              width: double.infinity,
              color: CareDropTheme.royalBlue,
              padding: const EdgeInsets.fromLTRB(20, 56, 20, 24),
              child: Row(
                children: [
                  UserAvatarWidget(
                    size: 56,
                    imageUrl: user.profilePictureUrl.isNotEmpty
                        ? user.profilePictureUrl
                        : appState.currentUserModel?.profilePictureUrl,
                  ),

                  const SizedBox(width: 16),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.fullName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              'Helper · ${user.verificationStatus}',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.check_circle_rounded,
                              color: Colors.white,
                              size: 14,
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const RatingsScreen(),
                              ),
                            );
                          },
                          child: Text(
                            '★ ${user.rating} · ${user.totalTasksCompleted} tasks',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Section 1: ACCOUNT
            _ProfileGroup(
              title: 'ACCOUNT',
              items: [
                _ProfileItem(
                  title: 'Personal Information',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const EditProfileScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),

            // Section 2: WORK
            _ProfileGroup(
              title: 'WORK',
              items: [
                _ProfileItem(
                  title: 'Service Areas',
                  onTap: () {},
                ),
                _ProfileItem(
                  title: 'Payout Settings',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PayoutSettingsScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),

            // Section 3: SUPPORT
            _ProfileGroup(
              title: 'SUPPORT',
              items: [
                _ProfileItem(
                  title: 'Help Center',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const HelpCenterScreen(),
                      ),
                    );
                  },
                ),
                _ProfileItem(
                  title: 'Settings',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SettingsScreen(),
                      ),
                    );
                  },
                ),
                _ProfileItem(
                  title: 'Sign Out',
                  isDestructive: true,
                  onTap: () async {
                    await FirebaseAuth.instance.signOut();
                    if (context.mounted) {
                      context.read<CareDropAppState>().clearSession();
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LandingScreen(),
                        ),
                        (route) => false,
                      );
                    }
                  },
                ),
              ],
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _ProfileGroup extends StatelessWidget {
  final String title;
  final List<_ProfileItem> items;

  const _ProfileGroup({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
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
              children: items.asMap().entries.map((entry) {
                final idx = entry.key;
                final item = entry.value;
                return Column(
                  children: [
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      title: Text(
                        item.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: item.isDestructive ? Colors.red : CareDropTheme.textPrimary,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.chevron_right_rounded,
                        size: 20,
                        color: CareDropTheme.textMuted,
                      ),
                      onTap: item.onTap,
                    ),
                    if (idx < items.length - 1)
                      const Divider(color: CareDropTheme.cardBorderColor, height: 1),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileItem {
  final String title;
  final bool isDestructive;
  final VoidCallback onTap;

  _ProfileItem({
    required this.title,
    this.isDestructive = false,
    required this.onTap,
  });
}
