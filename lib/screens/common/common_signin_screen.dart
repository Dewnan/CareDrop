import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../helper/helper_dashboard_screen.dart';
import '../patient/patient_dashboard_screen.dart';
import 'common_register_screen.dart';

class CommonSignInScreen extends StatefulWidget {
  const CommonSignInScreen({super.key});

  @override
  State<CommonSignInScreen> createState() => _CommonSignInScreenState();
}

class _CommonSignInScreenState extends State<CommonSignInScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    // Default to Patient demo user
    _emailController.text = MockUsers.patientUser.email;
    _passwordController.text = MockUsers.patientUser.password;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _fillMockUser(UserModel user) {
    setState(() {
      _emailController.text = user.email;
      _passwordController.text = user.password;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: CareDropTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Sign in',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: CareDropTheme.textPrimary,
                ),
              ),

              const SizedBox(height: 6),

              const Text(
                'Welcome back to CareDrop',
                style: TextStyle(
                  fontSize: 14,
                  color: CareDropTheme.textSecondary,
                ),
              ),

              const SizedBox(height: 24),

              // Demo User Quick Fill Bar
              const Text(
                'QUICK DEMO ACCOUNTS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: CareDropTheme.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        side: BorderSide(
                          color: _emailController.text == MockUsers.patientUser.email
                              ? CareDropTheme.royalBlue
                              : CareDropTheme.cardBorderColor,
                        ),
                      ),
                      onPressed: () => _fillMockUser(MockUsers.patientUser),
                      child: const Text('Patient Demo', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        side: BorderSide(
                          color: _emailController.text == MockUsers.helperUser.email
                              ? CareDropTheme.royalBlue
                              : CareDropTheme.cardBorderColor,
                        ),
                      ),
                      onPressed: () => _fillMockUser(MockUsers.helperUser),
                      child: const Text('Helper Demo', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              const Text(
                'EMAIL / PHONE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: CareDropTheme.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(hintText: 'email@caredrop.lk'),
              ),

              const SizedBox(height: 20),

              const Text(
                'PASSWORD',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: CareDropTheme.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: '••••••••',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: CareDropTheme.textMuted,
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
              ),

              const SizedBox(height: 12),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Forgot Password flow triggered!')),
                    );
                  },
                  child: const Text(
                    'Forgot Password?',
                    style: TextStyle(
                      color: CareDropTheme.royalBlue,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CareDropTheme.royalBlue,
                  ),
                  onPressed: () {
                    final email = _emailController.text.trim();
                    final password = _passwordController.text.trim();

                    if (email.isEmpty || password.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please fill in Email/Phone and Password.'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    // Route based on mock user email or helper keywords
                    if (email == MockUsers.helperUser.email || email.contains('helper')) {
                      context.read<CareDropAppState>().setRole(AppRole.helper);
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const HelperMainMainScreen()),
                        (route) => false,
                      );
                    } else {
                      context.read<CareDropAppState>().setRole(AppRole.patient);
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const PatientDashboardScreen()),
                        (route) => false,
                      );
                    }
                  },
                  child: const Text('Sign In'),
                ),
              ),

              const SizedBox(height: 28),

              Row(
                children: const [
                  Expanded(child: Divider(color: CareDropTheme.cardBorderColor)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'or',
                      style: TextStyle(color: CareDropTheme.textMuted, fontSize: 13),
                    ),
                  ),
                  Expanded(child: Divider(color: CareDropTheme.cardBorderColor)),
                ],
              ),

              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: CareDropTheme.cardBorderColor),
                    foregroundColor: CareDropTheme.textPrimary,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CommonRegisterScreen()),
                    );
                  },
                  child: const Text(
                    'Create Account',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
