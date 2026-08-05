import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../helper/helper_signin_screen.dart';

class SplashRoleScreen extends StatelessWidget {
  const SplashRoleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            children: [
              const SizedBox(height: 30),

              // Logo container
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.favorite_outline_rounded,
                  size: 36,
                  color: CareDropTheme.royalBlue,
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                'Welcome to CareDrop',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: CareDropTheme.textPrimary,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Who are you joining as?',
                style: TextStyle(
                  fontSize: 15,
                  color: CareDropTheme.textSecondary,
                ),
              ),

              const SizedBox(height: 40),

              // Role Card 1: Patient / Guardian
              _RoleCard(
                title: 'Patient / Guardian',
                description: 'Request assistance for hospital tasks',
                icon: Icons.favorite_outline_rounded,
                iconBg: const Color(0xFFEFF6FF),
                iconColor: CareDropTheme.royalBlue,
                borderColor: CareDropTheme.royalBlue,
                onTap: () {
                  context.read<CareDropAppState>().setRole(AppRole.patient);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Patient Role selected!'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),

              const SizedBox(height: 16),

              // Role Card 2: Helper
              _RoleCard(
                title: 'Helper',
                description: 'Earn by completing care tasks in your area',
                icon: Icons.medical_services_outlined,
                iconBg: const Color(0xFFE6F4F1),
                iconColor: CareDropTheme.tealPrimary,
                borderColor: CareDropTheme.tealPrimary,
                onTap: () {
                  context.read<CareDropAppState>().setRole(AppRole.helper);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const HelperSignInScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final Color borderColor;
  final VoidCallback onTap;

  const _RoleCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.borderColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: CareDropTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 13,
                      color: CareDropTheme.textSecondary,
                      height: 1.3,
                    ),
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
