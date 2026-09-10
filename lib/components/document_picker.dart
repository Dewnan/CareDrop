import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../services/permission_service.dart';
import '../theme/app_theme.dart';
import 'feedback_banner.dart';

/// Represents selected file metadata containing file name, local disk path, and byte content.
class PickedFileData {
  final String name;
  final String? path;
  final List<int>? bytes;

  const PickedFileData({
    required this.name,
    this.path,
    this.bytes,
  });
}

/// Captures an image from device camera or photo library using ImagePicker.
Future<PickedFileData?> pickImageFromSource(ImageSource source) async {
  try {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: source,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );

    if (image != null) {
      final bytes = await image.readAsBytes();
      return PickedFileData(
        name: image.name,
        path: image.path,
        bytes: bytes,
      );
    }
  } catch (e) {
    debugPrint('Failed to pick image: $e');
  }
  return null;
}

/// Opens device document picker to select PDF or image file.
Future<PickedFileData?> pickDocumentFile() async {
  try {
    final result = await FilePickerPlatform.instance.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg', 'doc', 'docx'],
    );

    if (result.isNotEmpty) {
      final file = result.first;
      final filePath = file.path;
      List<int>? fileBytes;
      if (filePath != null && filePath.isNotEmpty) {
        try {
          fileBytes = await File(filePath).readAsBytes();
        } catch (_) {}
      }
      return PickedFileData(
        name: file.name,
        path: filePath,
        bytes: fileBytes,
      );
    }
  } catch (e) {
    debugPrint('Failed to pick document: $e');
  }
  return null;
}

/// Displays modal bottom sheet for choosing between camera, gallery, or document files.
Future<PickedFileData?> showDocumentPicker(BuildContext context) async {
  return await showModalBottomSheet<PickedFileData>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => SafeArea(
      child: Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.picture_as_pdf_outlined, color: CareDropTheme.royalBlue),
            title: const Text('Choose Document (PDF / File)'),
            onTap: () async {
              final hasPermission = await PermissionService.requestStoragePermission();
              if (!hasPermission && ctx.mounted) {
                FeedbackBanner.show(
                  ctx,
                  message: 'Storage permission is required to select files.',
                  type: FeedbackType.warning,
                );
                return;
              }
              final result = await pickDocumentFile();
              if (ctx.mounted) Navigator.pop(ctx, result);
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_camera, color: CareDropTheme.royalBlue),
            title: const Text('Take a Photo (Camera)'),
            onTap: () async {
              final hasPermission = await PermissionService.requestCameraPermission();
              if (!hasPermission && ctx.mounted) {
                FeedbackBanner.show(
                  ctx,
                  message: 'Camera permission is required to capture photos.',
                  type: FeedbackType.warning,
                );
                return;
              }
              final result = await pickImageFromSource(ImageSource.camera);
              if (ctx.mounted) Navigator.pop(ctx, result);
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library, color: CareDropTheme.royalBlue),
            title: const Text('Choose from Gallery'),
            onTap: () async {
              final hasPermission = await PermissionService.requestStoragePermission();
              if (!hasPermission && ctx.mounted) {
                FeedbackBanner.show(
                  ctx,
                  message: 'Gallery permission is required to pick photos.',
                  type: FeedbackType.warning,
                );
                return;
              }
              final result = await pickImageFromSource(ImageSource.gallery);
              if (ctx.mounted) Navigator.pop(ctx, result);
            },
          ),
        ],
      ),
    ),
  );
}
