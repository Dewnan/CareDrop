import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../models/task_model.dart';
import '../../providers/app_state.dart';
import '../../services/image_cache_service.dart';
import '../../services/task_service.dart';
import '../../theme/app_theme.dart';
import 'helper_map_screen.dart';
import 'task_status_screen.dart';

/// Renders task details including clean patient name, location, inline document image preview, and full-screen viewer.
class TaskDetailsScreen extends StatelessWidget {
  final TaskModel task;

  const TaskDetailsScreen({
    super.key,
    required this.task,
  });

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<CareDropAppState>();
    final activeTask = appState.activeTask;
    final isAccepted = (activeTask?.id == task.id) || (task.progressStep != TaskProgressStep.pending);

    // Sanitize Patient Name
    final rawPatientInfo = task.patientInfo;
    final isPrefString = rawPatientInfo.contains('Sinhala') ||
        rawPatientInfo.contains('Tamil') ||
        rawPatientInfo.contains('English') ||
        rawPatientInfo.contains('preference');
    final displayPatientName = (isPrefString || rawPatientInfo.trim().isEmpty)
        ? (appState.currentUserModel?.fullName.isNotEmpty == true
            ? appState.currentUserModel!.fullName
            : 'Pesara Ranthila')
        : rawPatientInfo;

    // Sanitize Locations
    final cleanHospital = task.hospital.replaceAll('(select via map)', '').trim();
    final displayGeneralLocation = cleanHospital.isNotEmpty ? cleanHospital : 'General Hospital';

    final cleanPickup = task.locationDetail.replaceAll('(select via map)', '').replaceAll(', ,', '').trim();
    final displayPickupSpot = (cleanPickup.isNotEmpty && cleanPickup != ',') ? cleanPickup : '';

    return Scaffold(
      backgroundColor: CareDropTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Task Details',
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Main Task Summary Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: CareDropTheme.cardBorderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            task.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: CareDropTheme.textPrimary,
                            ),
                          ),
                        ),
                        Text(
                          '${task.currency} ${task.price.toInt()}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: CareDropTheme.royalBlue,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Urgent badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: task.isUrgent ? CareDropTheme.urgentBg : CareDropTheme.normalBg,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        task.isUrgent ? 'Urgent' : 'Normal',
                        style: TextStyle(
                          color: task.isUrgent ? CareDropTheme.urgentText : CareDropTheme.normalText,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                    const Divider(color: CareDropTheme.cardBorderColor, height: 1),
                    const SizedBox(height: 16),

                    _DetailItem(
                      label: 'Patient Name',
                      value: displayPatientName,
                    ),
                    const SizedBox(height: 12),
                    _DetailItem(
                      label: 'General Location',
                      value: displayGeneralLocation,
                    ),
                    if (displayPickupSpot.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _DetailItem(
                        label: 'Pickup Spot',
                        value: displayPickupSpot,
                      ),
                    ],

                    // Show exact Room & Bed details once accepted
                    if (isAccepted) ...[
                      const SizedBox(height: 12),
                      const _DetailItem(
                        label: 'Room & Bed No.',
                        value: 'Ward 4, Bed 12',
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Patient Contact',
                            style: TextStyle(
                              color: CareDropTheme.textMuted,
                              fontSize: 13,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFBFDBFE)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.phone, size: 14, color: CareDropTheme.royalBlue),
                                SizedBox(width: 4),
                                Text(
                                  '+94 77 123 4567',
                                  style: TextStyle(
                                    color: CareDropTheme.royalBlue,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 12),
                    _DetailItem(
                      label: 'Deadline',
                      value: task.deadline,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Description & Direct Image Display Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: CareDropTheme.cardBorderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: CareDropTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      task.description.isNotEmpty
                          ? task.description
                          : 'No additional typed instructions provided.',
                      style: const TextStyle(
                        fontSize: 13,
                        color: CareDropTheme.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    if (task.attachmentFileName != null && task.attachmentFileName!.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      const Divider(color: CareDropTheme.cardBorderColor),
                      const SizedBox(height: 12),
                      _AttachmentDirectPreview(
                        url: task.attachmentUrl,
                        fileName: task.attachmentFileName!,
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Action Buttons
              if (!isAccepted)
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CareDropTheme.royalBlue,
                    ),
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final navigator = Navigator.of(context);
                      final helperId = FirebaseAuth.instance.currentUser?.uid ?? '';

                      final success = await TaskService.acceptTask(
                        taskId: task.id,
                        helperId: helperId,
                      );

                      if (success) {
                        if (!context.mounted) return;
                        final acceptedTask = task.copyWith(
                          progressStep: TaskProgressStep.taskAccepted,
                          assignedHelperId: helperId,
                        );
                        context.read<CareDropAppState>().acceptTask(acceptedTask);

                        // Feedback SnackBar confirmation
                        messenger.showSnackBar(
                          SnackBar(
                            content: const Row(
                              children: [
                                Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text('Task Accepted'),
                                ),
                              ],
                            ),
                            backgroundColor: const Color(0xFF15803D),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            duration: const Duration(seconds: 3),
                          ),
                        );

                        navigator.pushReplacement(
                          MaterialPageRoute(
                            builder: (_) => TaskDetailsScreen(task: acceptedTask),
                          ),
                        );
                      } else {
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('This task has already been accepted by another helper!'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    child: Text(
                      'Accept Task - LKR ${task.price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: CareDropTheme.royalBlue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: const Icon(Icons.near_me_outlined, size: 18),
                          label: const Text(
                            'Navigate',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const HelperMapScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: CareDropTheme.royalBlue, width: 1.5),
                            foregroundColor: CareDropTheme.royalBlue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: const Icon(Icons.timer_outlined, size: 18),
                          label: const Text(
                            'Progress',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const TaskStatusScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Renders a clean direct image preview widget for task attachments.
class _AttachmentDirectPreview extends StatelessWidget {
  final String? url;
  final String fileName;

  const _AttachmentDirectPreview({
    required this.url,
    required this.fileName,
  });

  @override
  Widget build(BuildContext context) {
    final isNetwork = url != null && (url!.startsWith('http://') || url!.startsWith('https://'));
    final isFile = url != null && url!.isNotEmpty && !isNetwork && File(url!).existsSync();

    Widget imageWidget;
    if (isNetwork) {
      imageWidget = CachedNetworkImage(
        imageUrl: url!,
        cacheManager: ImageCacheService.instance,
        height: 220,
        width: double.infinity,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          height: 220,
          color: const Color(0xFFF1F5F9),
          child: const Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2, color: CareDropTheme.royalBlue),
            ),
          ),
        ),
        errorWidget: (context, url, error) => _buildPlaceholder(),
      );
    } else if (isFile) {
      imageWidget = Image.file(
        File(url!),
        height: 220,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
      );
    } else {
      imageWidget = _buildPlaceholder();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.attach_file_rounded, size: 16, color: CareDropTheme.royalBlue),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Attachment: $fileName',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: CareDropTheme.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _openFullImageDialog(context),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: CareDropTheme.cardBorderColor),
              ),
              child: imageWidget,
            ),
          ),
        ),
      ],
    );
  }

  /// Displays a full-screen zoomable dialog containing the full attachment image.
  void _openFullImageDialog(BuildContext context) {
    final isNetwork = url != null && (url!.startsWith('http://') || url!.startsWith('https://'));
    final isFile = url != null && url!.isNotEmpty && !isNetwork && File(url!).existsSync();

    Widget fullWidget;
    if (isNetwork) {
      fullWidget = CachedNetworkImage(
        imageUrl: url!,
        cacheManager: ImageCacheService.instance,
        fit: BoxFit.contain,
        placeholder: (context, url) => const Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
          ),
        ),
        errorWidget: (context, url, error) => _buildPlaceholder(height: null),
      );
    } else if (isFile) {
      fullWidget = Image.file(
        File(url!),
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(height: null),
      );
    } else {
      fullWidget = _buildPlaceholder(height: null);
    }

    showDialog(
      context: context,
      builder: (context) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 4.0,
                child: fullWidget,
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              right: 16,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 22),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Renders a placeholder image widget when an attachment image cannot be loaded directly.
  Widget _buildPlaceholder({double? height = 220}) {
    return Image.asset(
      'assets/images/prescription_placeholder.png',
      height: height,
      width: double.infinity,
      fit: height != null ? BoxFit.cover : BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => Image.asset(
        'assets/images/placeholder.png',
        height: height,
        width: double.infinity,
        fit: height != null ? BoxFit.cover : BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => Container(
          height: height ?? 200,
          width: double.infinity,
          color: const Color(0xFFF1F5F9),
          child: const Center(
            child: Icon(Icons.image_outlined, size: 48, color: CareDropTheme.royalBlue),
          ),
        ),
      ),
    );
  }
}

/// Renders a key-value detail item.
class _DetailItem extends StatelessWidget {
  final String label;
  final String value;

  const _DetailItem({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: CareDropTheme.textMuted,
            fontSize: 13,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: CareDropTheme.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}



