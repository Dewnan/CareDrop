import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/app_state.dart';
import '../../services/user_profile_service.dart';
import '../../services/permission_service.dart';
import '../../services/supabase_storage_service.dart';
import '../../components/user_avatar_widget.dart';
import '../../theme/app_theme.dart';
import '../../components/loading_indicator.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _icController;
  late String _selectedGender;
  bool _isLoading = false;

  XFile? _newPickedAvatarFile;
  Uint8List? _newAvatarBytes;

  @override
  void initState() {
    super.initState();
    final user = context.read<CareDropAppState>().currentUserModel;
    _nameController = TextEditingController(text: user?.fullName ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _icController = TextEditingController(text: user?.icNumber ?? '');
    _selectedGender = user?.gender.isNotEmpty == true ? user!.gender : 'Male';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _icController.dispose();
    super.dispose();
  }

  /// Prompts user to capture or select a new profile picture and validates that the file format is an image
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
                ? 'Camera permission is required to take a new profile picture.'
                : 'Storage / photo permission is required to choose a profile picture.',
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
          _newPickedAvatarFile = picked;
          _newAvatarBytes = bytes;
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
                'Change Profile Picture',
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

  Future<void> _saveProfile() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final ic = _icController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Full Name cannot be empty.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final appState = context.read<CareDropAppState>();
      final current = appState.currentUserModel;

      if (current != null) {
        String updatedAvatarUrl = current.profilePictureUrl;

        if (_newAvatarBytes != null && _newPickedAvatarFile != null) {
          final storage = SupabaseStorageService();
          final uploadedUrl = await storage.uploadAvatarBytes(
            bytes: _newAvatarBytes!,
            userId: current.id,
            fileName: _newPickedAvatarFile!.name,
          );
          if (uploadedUrl != null && uploadedUrl.isNotEmpty) {
            updatedAvatarUrl = uploadedUrl;
          }
        }

        await UserProfileService.updateUserProfile(
          uid: current.id,
          fullName: name,
          phone: phone,
          gender: _selectedGender,
          icNumber: ic,
          profilePictureUrl: updatedAvatarUrl,
        );

        final updatedModel = current.copyWith(
          fullName: name,
          phone: phone,
          gender: _selectedGender,
          icNumber: ic,
          profilePictureUrl: updatedAvatarUrl,
        );
        appState.setUserModel(updatedModel);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update profile: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
        title: const Text(
          'Edit Profile',
          style: TextStyle(color: CareDropTheme.textPrimary, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // PROFILE AVATAR EDIT SECTION
              Center(
                child: Consumer<CareDropAppState>(
                  builder: (context, appState, child) {
                    final currentUrl = appState.currentUserModel?.profilePictureUrl;
                    return Column(
                      children: [
                        UserAvatarWidget(
                          size: 96,
                          showEditBadge: true,
                          imageUrl: currentUrl,
                          localImageBytes: _newAvatarBytes,
                          localImageFile: kIsWeb || _newPickedAvatarFile == null
                              ? null
                              : File(_newPickedAvatarFile!.path),
                          onTap: _showAvatarSourcePicker,
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: _showAvatarSourcePicker,
                          child: const Text(
                            'Change Profile Picture',
                            style: TextStyle(
                              fontSize: 12,
                              color: CareDropTheme.royalBlue,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),

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
                controller: _nameController,
                decoration: const InputDecoration(hintText: 'Full Name'),
              ),

              const SizedBox(height: 20),

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

              const SizedBox(height: 20),

              // IC / ID NUMBER
              const Text(
                'IC / NATIONAL ID NUMBER',
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
                decoration: const InputDecoration(hintText: 'IC / NIC Number'),
              ),

              const SizedBox(height: 20),

              // GENDER
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
                        onTap: () => setState(() => _selectedGender = gender),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected ? CareDropTheme.royalBlue : CareDropTheme.cardBorderColor,
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              gender,
                              style: TextStyle(
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? CareDropTheme.royalBlue : CareDropTheme.textSecondary,
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

              const SizedBox(height: 36),

              // SAVE BUTTON
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CareDropTheme.royalBlue,
                    disabledBackgroundColor: CareDropTheme.royalBlue.withValues(alpha: 0.5),
                  ),
                  onPressed: _isLoading ? null : _saveProfile,
                  child: _isLoading
                      ? const AppLoadingIndicator(size: 20, color: Colors.white)
                      : const Text('Save Changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
