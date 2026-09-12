import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../components/loading_indicator.dart';
import '../../models/user_model.dart';
import '../../providers/app_state.dart';
import '../../services/user_session_service.dart';
import '../../theme/app_theme.dart';
import '../helper/helper_dashboard_screen.dart';
import '../patient/patient_dashboard_screen.dart';
import 'common_register_screen.dart';
import 'email_verification_screen.dart';

class CommonSignInScreen extends StatefulWidget {
  const CommonSignInScreen({super.key});

  @override
  State<CommonSignInScreen> createState() => _CommonSignInScreenState();
}

class _CommonSignInScreenState extends State<CommonSignInScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;

  bool _isLoading = false;

  // Rate limiting state variables to protect against brute force login attempts
  int _failedAttempts = 0;
  DateTime? _lockoutEndTime;
  static const int _maxAttempts = 3;
  static const int _lockoutDurationSeconds = 120;

  @override
  void initState() {
    super.initState();
    // Initialize text controllers empty for production login
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Checks if the user is currently rate limited due to too many failed attempts
  bool _isRateLimited(ScaffoldMessengerState messenger) {
    if (_lockoutEndTime != null) {
      if (DateTime.now().isBefore(_lockoutEndTime!)) {
        final remainingSec = _lockoutEndTime!.difference(DateTime.now()).inSeconds + 1;
        messenger.showSnackBar(
          SnackBar(
            content: Text('Too many failed attempts. Please try again in $remainingSec seconds.'),
            backgroundColor: Colors.red,
          ),
        );
        return true;
      } else {
        // Lockout period has elapsed; reset counters
        _lockoutEndTime = null;
        _failedAttempts = 0;
      }
    }
    return false;
  }

  // Increments failed attempt count and applies rate limit lockout if threshold reached
  void _recordFailedAttempt(ScaffoldMessengerState messenger, String errorDetails) {
    _failedAttempts++;
    if (_failedAttempts >= _maxAttempts) {
      _lockoutEndTime = DateTime.now().add(const Duration(seconds: _lockoutDurationSeconds));
      _failedAttempts = 0;
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Too many failed attempts (3/3). Login locked for 2 minutes.'),
          backgroundColor: Colors.red,
        ),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text('$errorDetails (Attempt $_failedAttempts/$_maxAttempts)'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _fillMockUser(UserModel user) {
    setState(() {
      _emailController.text = user.email;
      _passwordController.text = 'Dewnan@2003';
    });
  }

  void _showForgotPasswordDialog(BuildContext context) {
    final resetEmailController = TextEditingController(text: _emailController.text.trim());

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Reset Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter your registered email address below. We will send you a password reset link.',
                style: TextStyle(fontSize: 13, color: CareDropTheme.textSecondary),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: resetEmailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  hintText: 'email@example.com',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: CareDropTheme.royalBlue,
              ),
              onPressed: () async {
                final email = resetEmailController.text.trim();
                if (email.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter your email address.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                try {
                  await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Password reset email sent to $email'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } on FirebaseAuthException catch (e) {
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(e.message ?? 'Failed to send reset email'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Send Reset Link'),
            ),
          ],
        );
      },
    );
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
                  onPressed: () => _showForgotPasswordDialog(context),
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
                    disabledBackgroundColor: CareDropTheme.royalBlue.withValues(alpha: 0.5),
                  ),
                  onPressed: _isLoading
                      ? null
                      : () async {
                          final messenger = ScaffoldMessenger.of(context);
                          final appState = context.read<CareDropAppState>();
                          final navigator = Navigator.of(context);
                          final email = _emailController.text.trim();
                          final password = _passwordController.text.trim();

                          // Prevent sign in if user is locked out due to rate limit
                          if (_isRateLimited(messenger)) {
                            return;
                          }

                          if (email.isEmpty || password.isEmpty) {
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('Please fill in Email and Password.'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          setState(() => _isLoading = true);

                          try {
                            final creds = await FirebaseAuth.instance.signInWithEmailAndPassword(
                              email: email,
                              password: password,
                            );

                            if (creds.user != null) {
                              // Reset rate limit counters on successful authentication
                              _failedAttempts = 0;
                              _lockoutEndTime = null;

                              final userRole = (email == MockUsers.helperUser.email || email.contains('helper')) ? 'helper' : 'patient';

                              // Check if email is verified
                              if (!creds.user!.emailVerified) {
                                if (mounted) setState(() => _isLoading = false);
                                navigator.push(
                                  MaterialPageRoute(
                                    builder: (_) => EmailVerificationScreen(
                                      userRole: userRole,
                                      email: email,
                                    ),
                                  ),
                                );
                                return;
                              }

                              final fetchedProfile = await UserSessionService.fetchUserProfile(creds.user!.uid);
                              if (fetchedProfile != null) {
                                appState.setUserModel(fetchedProfile);
                              } else {
                                final newProfile = UserModel(
                                  id: creds.user!.uid,
                                  email: email,
                                  fullName: creds.user!.displayName ?? (userRole == 'helper' ? 'Helper User' : 'Patient User'),
                                  role: userRole,
                                  gender: 'Not Specified',
                                  phone: creds.user!.phoneNumber ?? '',
                                );
                                appState.setUserModel(newProfile);
                              }
                            }
                          } on FirebaseAuthException catch (e) {
                            if (mounted) setState(() => _isLoading = false);
                            debugPrint('Error: ${e.message}');
                            // Record failed attempt for rate limiting
                            _recordFailedAttempt(messenger, e.message ?? 'Authentication failed');
                            return;
                          } catch (e) {
                            if (mounted) setState(() => _isLoading = false);
                            debugPrint('Error: $e');
                            // Record failed attempt for rate limiting
                            _recordFailedAttempt(messenger, 'An unexpected error occurred: $e');
                            return;
                          }

                          if (!mounted) return;

                          final userRole = appState.currentUserModel?.role.toLowerCase() ??
                              ((email == MockUsers.helperUser.email || email.contains('helper')) ? 'helper' : 'patient');

                          if (userRole == 'helper') {
                            navigator.pushAndRemoveUntil(
                              MaterialPageRoute(builder: (_) => const HelperMainMainScreen()),
                              (route) => false,
                            );
                          } else {
                            navigator.pushAndRemoveUntil(
                              MaterialPageRoute(builder: (_) => const PatientDashboardScreen()),
                              (route) => false,
                            );
                          }
                        },
                  child: _isLoading
                      ? const AppLoadingIndicator(color: Colors.white, size: 24)
                      : const Text('Sign In'),
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
