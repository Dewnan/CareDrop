import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/user_model.dart';
import '../../providers/app_state.dart';
import '../../services/user_profile_service.dart';
import '../../services/permission_service.dart';
import '../../services/supabase_storage_service.dart';
import '../../components/user_avatar_widget.dart';
import '../../theme/app_theme.dart';
import '../../components/loading_indicator.dart';
import 'email_verification_screen.dart';

class CommonRegisterScreen extends StatefulWidget {
  const CommonRegisterScreen({super.key});

  @override
  State<CommonRegisterScreen> createState() => _CommonRegisterScreenState();
}

class _CommonRegisterScreenState extends State<CommonRegisterScreen> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _icController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String _selectedRole = 'Patient / Guardian';
  String _selectedGender = 'Male';
  bool _obscurePassword = true;
  bool _isLoading = false;

  XFile? _pickedAvatarFile;
  Uint8List? _avatarBytes;

  @override
  void initState() {
    super.initState();
    // Default initial role from app state if set
    final currentRole = context.read<CareDropAppState>().currentRole;
    if (currentRole == AppRole.helper) {
      _selectedRole = 'Helper';
    } else {
      _selectedRole = 'Patient / Guardian';
    }
  }

  /// Prompts user with camera or gallery selection and checks image file extension before setting state
  Future<void> _pickAvatarImage(ImageSource source) async {
    final messenger = ScaffoldMessenger.of(context);
    final hasPermission = source == ImageSource.camera
        ? await PermissionService.requestCameraPermission()
        : await PermissionService.requestStoragePermission();

    if (!hasPermission) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            source == ImageSource.camera
                ? 'Camera permission is required to capture a profile picture.'
                : 'Storage / photo permission is required to select a profile picture.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (picked != null) {
        if (!SupabaseStorageService.isImageFileName(picked.name)) {
          messenger.showSnackBar(
            const SnackBar(
              content: Text('Invalid file format. Please select an image file (JPG, PNG, WEBP).'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        final bytes = await picked.readAsBytes();
        setState(() {
          _pickedAvatarFile = picked;
          _avatarBytes = bytes;
        });
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Failed to pick profile picture: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Displays bottom sheet to choose avatar image source (camera vs photo gallery)
  void _showAvatarSourcePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Select Profile Picture',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: CareDropTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: CareDropTheme.royalBlue),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAvatarImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: CareDropTheme.royalBlue),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAvatarImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _icController.dispose();
    _phoneController.dispose();
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
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 20,
            color: CareDropTheme.textPrimary,
          ),
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
                'Create Account',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: CareDropTheme.textPrimary,
                ),
              ),

              const SizedBox(height: 6),

              const Text(
                'Join CareDrop to request or provide help',
                style: TextStyle(
                  fontSize: 14,
                  color: CareDropTheme.textSecondary,
                ),
              ),

              const SizedBox(height: 20),

              // PROFILE PICTURE SELECTOR
              Center(
                child: Column(
                  children: [
                    UserAvatarWidget(
                      size: 90,
                      showEditBadge: true,
                      localImageBytes: _avatarBytes,
                      localImageFile: kIsWeb || _pickedAvatarFile == null
                          ? null
                          : File(_pickedAvatarFile!.path),
                      onTap: _showAvatarSourcePicker,
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _showAvatarSourcePicker,
                      child: const Text(
                        'Tap to set profile picture (Optional)',
                        style: TextStyle(
                          fontSize: 12,
                          color: CareDropTheme.royalBlue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ROLE SELECTION
              const Text(
                'I AM JOINING AS A',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: CareDropTheme.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: ['Patient / Guardian', 'Helper'].map((role) {
                  final isSelected = _selectedRole == role;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _selectedRole = role;
                          });
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          height: 46,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFEFF6FF)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected
                                  ? CareDropTheme.royalBlue
                                  : CareDropTheme.cardBorderColor,
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              role,
                              style: TextStyle(
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isSelected
                                    ? CareDropTheme.royalBlue
                                    : CareDropTheme.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),

              // FULL NAME
              const Text(
                'FULL NAME',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: CareDropTheme.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _fullNameController,
                decoration: const InputDecoration(hintText: 'Full Name'),
              ),

              const SizedBox(height: 16),

              // IC / ID NUMBER
              const Text(
                'NIC NUMBER',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: CareDropTheme.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _icController,
                decoration: const InputDecoration(hintText: 'NIC Number'),
              ),

              const SizedBox(height: 16),

              // GENDER SELECTION (Positioned between NIC Number and Phone Number; Male & Female choices)
              const Text(
                'GENDER',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: CareDropTheme.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: ['Male', 'Female'].map((gender) {
                  final isSelected = _selectedGender == gender;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _selectedGender = gender;
                          });
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFEFF6FF)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected
                                  ? CareDropTheme.royalBlue
                                  : CareDropTheme.cardBorderColor,
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              gender,
                              style: TextStyle(
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isSelected
                                    ? CareDropTheme.royalBlue
                                    : CareDropTheme.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 16),

              // PHONE
              const Text(
                'PHONE NUMBER',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: CareDropTheme.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(hintText: '+94 70 000 0000'),
              ),

              const SizedBox(height: 16),

              // EMAIL
              const Text(
                'EMAIL ADDRESS',
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
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  hintText: 'email@example.com',
                ),
              ),

              const SizedBox(height: 16),

              // PASSWORD
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
                onChanged: (_) => setState(() {}),
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

              const SizedBox(height: 10),

              // Password Requirements List
              _buildPasswordRequirementsList(_passwordController.text),

              const SizedBox(height: 28),

              // CREATE ACCOUNT BUTTON
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

                          if (_fullNameController.text.trim().isEmpty ||
                              email.isEmpty ||
                              password.isEmpty) {
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('Please complete required fields.'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          // Password validation requirements
                          if (password.length < 6 || password.length > 16) {
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('Password must be between 6 and 16 characters long.'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          if (!RegExp(r'[A-Z]').hasMatch(password)) {
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('Password must contain at least one uppercase letter (A-Z).'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          if (!RegExp(r'[a-z]').hasMatch(password)) {
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('Password must contain at least one lowercase letter (a-z).'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          if (!RegExp(r'[0-9]').hasMatch(password)) {
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('Password must contain at least one numeric digit (0-9).'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) {
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('Password must contain at least one special character (e.g. !@#\$%^&*).'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          setState(() => _isLoading = true);

                          try {
                            final userCredential = await FirebaseAuth.instance
                                .createUserWithEmailAndPassword(
                                  email: email,
                                  password: password,
                                );

                            final user = userCredential.user;
                            if (user != null) {
                              final icNumber = _icController.text.trim();
                              if (icNumber.isNotEmpty) {
                                final nicQuery = await FirebaseFirestore.instance
                                    .collection('users')
                                    .where('icNumber', isEqualTo: icNumber)
                                    .limit(1)
                                    .get();

                                if (nicQuery.docs.isNotEmpty) {
                                  await user.delete(); // Rollback user creation
                                  if (mounted) setState(() => _isLoading = false);
                                  messenger.showSnackBar(
                                    const SnackBar(
                                      content: Text('An account with this NIC number already exists.'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }
                              }
                              // Send verification email
                              await user.sendEmailVerification();

                              String uploadedAvatarUrl = '';
                              if (_avatarBytes != null && _pickedAvatarFile != null) {
                                try {
                                  final storage = SupabaseStorageService();
                                  final url = await storage.uploadAvatarBytes(
                                    bytes: _avatarBytes!,
                                    userId: user.uid,
                                    fileName: _pickedAvatarFile!.name,
                                  );
                                  if (url != null) {
                                    uploadedAvatarUrl = url;
                                  }
                                } catch (uploadErr) {
                                  debugPrint('Avatar upload error during registration: $uploadErr');
                                }
                              }

                              final roleStr = _selectedRole == 'Helper' ? 'helper' : 'patient';
                              final newUserModel = UserModel(
                                id: user.uid,
                                email: email,
                                fullName: _fullNameController.text.trim(),
                                role: roleStr,
                                gender: _selectedGender,
                                phone: _phoneController.text.trim(),
                                icNumber: _icController.text.trim(),
                                profilePictureUrl: uploadedAvatarUrl,
                              );

                              await UserProfileService.createUserProfile(newUserModel);
                              appState.setUserModel(newUserModel);

                              if (!mounted) return;

                              // Navigate to Email Verification screen
                              navigator.pushReplacement(
                                MaterialPageRoute(
                                  builder: (_) => EmailVerificationScreen(
                                    userRole: roleStr,
                                    email: email,
                                  ),
                                ),
                              );
                              return;
                            }
                          } on FirebaseAuthException catch (e) {
                            if (mounted) setState(() => _isLoading = false);
                            debugPrint('Error: ${e.code} - ${e.message}');
                            final errorMsg = e.code == 'email-already-in-use'
                                ? 'This email address is already registered.'
                                : (e.message ?? 'Registration failed');
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(errorMsg),
                                backgroundColor: Colors.red,
                              ),
                            );
                          } catch (e) {
                            if (mounted) setState(() => _isLoading = false);
                            debugPrint('Error: $e');
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text('An unexpected error occurred: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                  child: _isLoading
                      ? const AppLoadingIndicator(color: Colors.white, size: 24)
                      : const Text('Register Account'),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordRequirementsList(String pwd) {
    final hasLength = pwd.length >= 6 && pwd.length <= 16;
    final hasUpper = RegExp(r'[A-Z]').hasMatch(pwd);
    final hasLower = RegExp(r'[a-z]').hasMatch(pwd);
    final hasDigit = RegExp(r'[0-9]').hasMatch(pwd);
    final hasSpecial = RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(pwd);

    Widget item(bool met, String label) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          children: [
            Icon(
              met ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
              size: 14,
              color: met ? Colors.green : CareDropTheme.textMuted,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: met ? Colors.green : CareDropTheme.textMuted,
                fontWeight: met ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        item(hasLength, '6 to 16 characters long'),
        item(hasUpper, 'At least one uppercase letter (A-Z)'),
        item(hasLower, 'At least one lowercase letter (a-z)'),
        item(hasDigit, 'At least one numeric digit (0-9)'),
        item(hasSpecial, 'At least one special character (!@#\$%^&*)'),
      ],
    );
  }
}
