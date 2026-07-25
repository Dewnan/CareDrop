import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../screens/helper/helper_register_screen.dart';

class HelperSignInScreen extends StatefulWidget {
  const HelperSignInScreen({super.key});

  @override
  State<HelperSignInScreen> createState() => _HelperSignInScreenState();
}

class _HelperSignInScreenState extends State<HelperSignInScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;

  // clean fields on destroy
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
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
                'Helper Sign in',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: CareDropTheme.textPrimary,
                ),
              ),

              const SizedBox(height: 6),

              const Text(
                'Start earning with CareDrop',
                style: TextStyle(
                  fontSize: 14,
                  color: CareDropTheme.textSecondary,
                ),
              ),

              const SizedBox(height: 36),

              // Email input field
              const Text(
                'EMAIL',
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
                decoration: const InputDecoration(hintText: 'Email'),
              ),

              const SizedBox(height: 20),

              // Passwrod input field
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
                  hintText: 'Enter password',
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

              // Tempery Messege, remove later
              Align(
                alignment: Alignment.center,
                child: TextButton(
                  onPressed: () {},
                  child: const Text(
                    'Use any Email and Password for testing',
                    style: TextStyle(
                      color: Color.fromARGB(255, 144, 10, 7),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),

              // Forgot password
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Forgot Password Triggerd!'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  child: const Text(
                    'Forgot Password?',
                    style: TextStyle(
                      color: CareDropTheme.tealPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Sign In Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CareDropTheme.tealPrimary,
                  ),
                  //show sign in messege
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Signin Triggerd!'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  child: const Text('Sign In'),
                ),
              ),

              const SizedBox(height: 28),

              // TODO: Implement Google SSO authentication
              // Divider "or"
              Row(
                children: [
                  const Expanded(
                    child: Divider(color: CareDropTheme.cardBorderColor),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'or',
                      style: TextStyle(
                        color: CareDropTheme.textMuted,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const Expanded(
                    child: Divider(color: CareDropTheme.cardBorderColor),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // Become a Helper button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(
                      color: CareDropTheme.cardBorderColor,
                    ),
                    foregroundColor: CareDropTheme.textPrimary,
                  ),
                  // load the helper registration interface
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const HelperRegisterScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    'Become a Helper',
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
