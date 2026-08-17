import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../common/edit_profile_screen.dart';
import '../common/landing_screen.dart';

class PatientProfileScreen extends StatelessWidget {
  const PatientProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<CareDropAppState>();
    final user = appState.currentUserModel;
    final fullName = user?.fullName ?? 'Patient User';
    final initials = fullName.split(' ').take(2).map((e) => e.isNotEmpty ? e[0] : '').join();
    final role = user?.role ?? 'patient';
    final phone = user?.phone ?? '';

    return Scaffold(
      backgroundColor: CareDropTheme.backgroundColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top Blue Header
            Container(
              width: double.infinity,
              color: CareDropTheme.royalBlue,
              padding: const EdgeInsets.fromLTRB(20, 56, 20, 24),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        initials.isEmpty ? 'P' : initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fullName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$role ${phone.isNotEmpty ? '· $phone' : ''}',
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Active Patient',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
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
                  // ACCOUNT SECTION
                  const Text(
                    'ACCOUNT',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: CareDropTheme.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildMenuCard([
                    _buildMenuItem(
                      Icons.person_outline,
                      'Personal Information',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const EditProfileScreen(),
                          ),
                        );
                      },
                    ),
                    _buildMenuItem(Icons.security_outlined, 'Security Settings'),
                    _buildMenuItem(Icons.payment_outlined, 'Payment Methods', isLast: true),
                  ]),

                  const SizedBox(height: 24),

                  // PREFERENCES SECTION
                  const Text(
                    'PREFERENCES',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: CareDropTheme.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildMenuCard([
                    _buildMenuItem(Icons.notifications_outlined, 'Notifications'),
                    _buildMenuItem(Icons.location_on_outlined, 'Saved Locations', isLast: true),
                  ]),

                  const SizedBox(height: 24),

                  // SUPPORT SECTION
                  const Text(
                    'SUPPORT',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: CareDropTheme.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildMenuCard([
                    _buildMenuItem(Icons.help_outline, 'Help Center'),
                    _buildMenuItem(
                      Icons.logout,
                      'Sign Out',
                      isDestructive: true,
                      isLast: true,
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
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(List<Widget> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CareDropTheme.cardBorderColor),
      ),
      child: Column(children: items),
    );
  }

  Widget _buildMenuItem(
    IconData icon,
    String title, {
    bool isDestructive = false,
    bool isLast = false,
    VoidCallback? onTap,
  }) {
    return Column(
      children: [
        ListTile(
          leading: Icon(
            icon,
            color: isDestructive ? const Color(0xFFEF4444) : CareDropTheme.textSecondary,
            size: 22,
          ),
          title: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDestructive ? const Color(0xFFEF4444) : CareDropTheme.textPrimary,
            ),
          ),
          trailing: isDestructive
              ? null
              : const Icon(Icons.chevron_right, size: 20, color: CareDropTheme.textMuted),
          onTap: onTap,
        ),
        if (!isLast) const Divider(height: 1, color: CareDropTheme.cardBorderColor),
      ],
    );
  }
}
