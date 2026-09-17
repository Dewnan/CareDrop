import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../components/feedback_banner.dart';
import '../../components/loading_indicator.dart';
import '../../components/route_preview_map.dart';
import '../../components/task/task_detail_row.dart';
import '../../models/task_model.dart';
import '../../providers/app_state.dart';
import '../../services/image_cache_service.dart';
import '../../services/task_service.dart';
import '../../theme/app_theme.dart';
import 'task_status_screen.dart';
import 'helper_map_screen.dart';

/// Renders task details including clean patient name, location, inline document image preview, and full-screen viewer.
class TaskDetailsScreen extends StatefulWidget {
  final TaskModel task;

  const TaskDetailsScreen({
    super.key,
    required this.task,
  });

  @override
  State<TaskDetailsScreen> createState() => _TaskDetailsScreenState();
}

class _TaskDetailsScreenState extends State<TaskDetailsScreen> {
  bool _isAccepting = false;

  /// Opens Google Maps / External Maps app using target GPS coordinates or location address.
  Future<void> _openExternalMaps(double? lat, double? lng, String fallbackAddress) async {
    final query = (lat != null && lng != null)
        ? '$lat,$lng'
        : Uri.encodeComponent(fallbackAddress);
    final googleMapsUrl = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final appState = context.watch<CareDropAppState>();
    final isAccepted = task.assignedHelperId != null || appState.activeTask?.id == task.id;
    final customerPhone = appState.currentUserModel?.phone.isNotEmpty == true
        ? appState.currentUserModel!.phone
        : '+94 77 123 4567';

    // Use the full name from the logged-in user's profile as the display patient name
    final displayPatientName = appState.currentUserModel?.fullName.isNotEmpty == true
        ? appState.currentUserModel!.fullName
        : 'Patient';

    // Format Pickup and Dropoff Locations cleanly
    final cleanPickup = task.pickupAddress.replaceAll('(select via map)', '').replaceAll(', ,', '').trim();
    final displayPickupLocation = cleanPickup.isNotEmpty ? cleanPickup : 'General Hospital Pickup';

    String cleanDropoff = '';
    if (task.dropoffAddress != null && task.dropoffAddress!.isNotEmpty) {
      cleanDropoff = task.dropoffAddress!.replaceAll('(select via map)', '').replaceAll(', ,', '').trim();
    } else if (task.roomDetail.isNotEmpty &&
        task.roomDetail != task.pickupAddress &&
        task.roomDetail != displayPickupLocation) {
      cleanDropoff = task.roomDetail.replaceAll('(select via map)', '').replaceAll(', ,', '').trim();
    }
    final displayDropoffLocation = cleanDropoff.isNotEmpty ? cleanDropoff : 'Dropoff Point / Patient Ward';

    // Format Room & Bed details cleanly: hide when empty or identical to pickup/dropoff
    String? roomBedDetail;
    if (task.roomDetail.isNotEmpty && !task.roomDetail.contains('(select via map)')) {
      final candidate = task.roomDetail.replaceAll(', ,', '').trim();
      if (candidate.isNotEmpty &&
          candidate != displayPickupLocation &&
          candidate != displayDropoffLocation &&
          candidate != task.pickupAddress &&
          candidate != task.dropoffAddress) {
        roomBedDetail = candidate;
      }
    }

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
            color: CareDropTheme.normalBg,
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

                    if (task.paymentMethod != null && task.paymentMethod!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Payment Method',
                            style: TextStyle(color: CareDropTheme.textMuted, fontSize: 13),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: task.paymentMethod!.toLowerCase().contains('payhere') ||
                                      task.paymentMethod!.toLowerCase().contains('online') ||
                                      task.paymentMethod!.toLowerCase().contains('card') ||
                                      task.paymentMethod!.toLowerCase().contains('escrow')
                                  ? const Color(0xFFEFF6FF)
                                  : const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: task.paymentMethod!.toLowerCase().contains('payhere') ||
                                        task.paymentMethod!.toLowerCase().contains('online') ||
                                        task.paymentMethod!.toLowerCase().contains('card') ||
                                        task.paymentMethod!.toLowerCase().contains('escrow')
                                    ? CareDropTheme.royalBlue
                                    : CareDropTheme.cardBorderColor,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  task.paymentMethod!.toLowerCase().contains('payhere') ||
                                          task.paymentMethod!.toLowerCase().contains('online') ||
                                          task.paymentMethod!.toLowerCase().contains('card') ||
                                          task.paymentMethod!.toLowerCase().contains('escrow')
                                      ? Icons.lock_outline
                                      : Icons.payments_outlined,
                                  size: 14,
                                  color: task.paymentMethod!.toLowerCase().contains('payhere') ||
                                          task.paymentMethod!.toLowerCase().contains('online') ||
                                          task.paymentMethod!.toLowerCase().contains('card') ||
                                          task.paymentMethod!.toLowerCase().contains('escrow')
                                      ? CareDropTheme.royalBlue
                                      : CareDropTheme.textSecondary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  task.paymentMethod!.toLowerCase().contains('payhere') ||
                                          task.paymentMethod!.toLowerCase().contains('online') ||
                                          task.paymentMethod!.toLowerCase().contains('card') ||
                                          task.paymentMethod!.toLowerCase().contains('escrow')
                                      ? 'Online Escrow (Secured)'
                                      : 'Cash on Delivery',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: task.paymentMethod!.toLowerCase().contains('payhere') ||
                                            task.paymentMethod!.toLowerCase().contains('online') ||
                                            task.paymentMethod!.toLowerCase().contains('card') ||
                                            task.paymentMethod!.toLowerCase().contains('escrow')
                                        ? CareDropTheme.royalBlue
                                        : CareDropTheme.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],



                    const SizedBox(height: 12),
                    TaskDetailRow(
                      label: 'Patient Name',
                      value: displayPatientName,
                    ),
                    const SizedBox(height: 12),
                    TaskDetailRow(
                      label: 'Pickup Location',
                      value: displayPickupLocation,
                    ),
                    if (displayDropoffLocation != displayPickupLocation && displayDropoffLocation.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      TaskDetailRow(
                        label: 'Dropoff Location',
                        value: displayDropoffLocation,
                      ),
                    ],

                    // Route Preview Map for Helpers
                    if (task.pickupLat != null && task.pickupLng != null && task.dropoffLat != null && task.dropoffLng != null) ...[
                      const SizedBox(height: 16),
                      RoutePreviewMap(
                        pickupLocation: LatLng(task.pickupLat!, task.pickupLng!),
                        dropoffLocation: LatLng(task.dropoffLat!, task.dropoffLng!),
                        pickupAddress: displayPickupLocation,
                        dropoffAddress: displayDropoffLocation,
                        isAccepted: isAccepted,
                      ),
                    ],


                    // Show exact Room & Bed details once accepted
                    if (isAccepted && roomBedDetail != null && roomBedDetail.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      TaskDetailRow(
                        label: 'Room & Bed No.',
                        value: roomBedDetail,
                      ),
                    ],

                    if (isAccepted) ...[
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
                          Text(
                            customerPhone,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: CareDropTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ],

                    if (task.deadline.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      TaskDetailRow(
                        label: 'Deadline',
                        value: task.deadline,
                      ),
                    ],
                  ],
                ),
              ),

              // Medicine & Item Pickup Card (Shown ONLY when medicine/item data exists)
              if ((task.itemName != null && task.itemName!.isNotEmpty) ||
                  (task.itemQuantity != null && task.itemQuantity!.isNotEmpty) ||
                  (task.itemSpecialInstructions != null && task.itemSpecialInstructions!.isNotEmpty)) ...[
                const SizedBox(height: 16),
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
                      const Row(
                        children: [
                          Icon(Icons.medication_outlined, color: CareDropTheme.royalBlue, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Medicine / Item Details',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: CareDropTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      if (task.itemName != null && task.itemName!.isNotEmpty) ...[
                        TaskDetailRow(label: 'Item / Medicine Name', value: task.itemName!),
                        const SizedBox(height: 10),
                      ],
                      if (task.itemQuantity != null && task.itemQuantity!.isNotEmpty) ...[
                        TaskDetailRow(label: 'Quantity / Dose', value: task.itemQuantity!),
                        const SizedBox(height: 10),
                      ],
                      if (task.itemSpecialInstructions != null && task.itemSpecialInstructions!.isNotEmpty) ...[
                        TaskDetailRow(label: 'Item Special Notes', value: task.itemSpecialInstructions!),
                      ],
                    ],
                  ),
                ),
              ],

              // Caregiver Preferences Card (Shown ONLY when caregiver preference data exists)
              if ((task.serviceDuration != null && task.serviceDuration!.isNotEmpty) ||
                  (task.preferredGender != null && task.preferredGender!.isNotEmpty) ||
                  (task.preferredLanguage != null && task.preferredLanguage!.isNotEmpty)) ...[
                const SizedBox(height: 16),
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
                      const Row(
                        children: [
                          Icon(Icons.person_outline, color: CareDropTheme.royalBlue, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Caregiver Service Preferences',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: CareDropTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      if (task.serviceDuration != null && task.serviceDuration!.isNotEmpty) ...[
                        TaskDetailRow(label: 'Service Duration', value: task.serviceDuration!),
                        const SizedBox(height: 10),
                      ],
                      if (task.preferredGender != null && task.preferredGender!.isNotEmpty) ...[
                        TaskDetailRow(label: 'Preferred Gender', value: task.preferredGender!),
                        const SizedBox(height: 10),
                      ],
                      if (task.preferredLanguage != null && task.preferredLanguage!.isNotEmpty) ...[
                        TaskDetailRow(label: 'Required Language', value: task.preferredLanguage!),
                      ],
                    ],
                  ),
                ),
              ],

              // Instructions & Attached Document/Prescription Card
              if (task.description.isNotEmpty || (task.attachmentUrl != null && task.attachmentUrl!.isNotEmpty)) ...[
                const SizedBox(height: 16),
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
                        'Instructions & Attachments',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: CareDropTheme.textPrimary,
                        ),
                      ),
                      if (task.description.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          task.description,
                          style: const TextStyle(
                            fontSize: 13,
                            color: CareDropTheme.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ],
                      if (task.attachmentUrl != null && task.attachmentUrl!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        const Divider(color: CareDropTheme.cardBorderColor, height: 1),
                        const SizedBox(height: 16),
                        const Text(
                          'Attached Document / Prescription',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: CareDropTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _DocumentImagePreview(
                          imageUrl: task.attachmentUrl!,
                          fileName: task.attachmentFileName ?? 'Prescription / Document',
                        ),
                      ],
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Bottom Action Button
              if (!isAccepted) ...[
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CareDropTheme.royalBlue,
                      disabledBackgroundColor: CareDropTheme.royalBlue.withValues(alpha: 0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _isAccepting
                        ? null
                        : () async {
                            final currentUser = FirebaseAuth.instance.currentUser;
                            final helperId = currentUser?.uid ?? appState.currentUserModel?.id;

                            if (helperId == null || helperId.isEmpty) {
                              if (!context.mounted) return;
                              FeedbackBanner.show(
                                context,
                                message: 'Please log in as a Helper to accept tasks.',
                                type: FeedbackType.error,
                              );
                              return;
                            }

                            setState(() => _isAccepting = true);

                            try {
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

                                FeedbackBanner.show(
                                  context,
                                  message: 'Task Accepted! Review full details or tap Navigate Map.',
                                  type: FeedbackType.success,
                                );
                              } else {
                                if (!context.mounted) return;
                                FeedbackBanner.show(
                                  context,
                                  message: 'This task has already been accepted by another helper!',
                                  type: FeedbackType.error,
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                FeedbackBanner.show(
                                  context,
                                  message: 'Failed to accept task: $e',
                                  type: FeedbackType.error,
                                );
                              }
                            } finally {
                              if (mounted) {
                                setState(() => _isAccepting = false);
                              }
                            }
                          },
                    child: _isAccepting
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AppLoadingIndicator(size: 20, color: Colors.white),
                              SizedBox(width: 12),
                              Text(
                                'Accepting Task...',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ],
                          )
                        : Text(
                            'Accept Task - LKR ${task.price.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ] else ...[
                Row(
                  children: [
                    SizedBox(
                      height: 52,
                      width: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEFF6FF),
                          foregroundColor: CareDropTheme.royalBlue,
                          padding: EdgeInsets.zero,
                          elevation: 0,
                          side: const BorderSide(color: CareDropTheme.royalBlue),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () async {
                          final uri = Uri.parse('tel:${customerPhone.replaceAll(' ', '')}');
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri);
                          }
                        },
                        child: const Icon(Icons.phone, color: CareDropTheme.royalBlue, size: 24),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: CareDropTheme.royalBlue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.navigation_outlined, color: Colors.white, size: 20),
                          label: const Text(
                            'Navigate Map',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => HelperMapScreen(task: task),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 52,
                      width: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFEF3C7),
                          foregroundColor: const Color(0xFFD97706),
                          padding: EdgeInsets.zero,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => _openExternalMaps(
                          task.pickupLat,
                          task.pickupLng,
                          displayPickupLocation,
                        ),
                        child: const Icon(Icons.map_outlined, color: Color(0xFFD97706), size: 22),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 52,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: CareDropTheme.cardBorderColor),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const TaskStatusScreen(),
                            ),
                          );
                        },
                        child: const Icon(Icons.tune, color: CareDropTheme.textPrimary, size: 22),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Renders a clean direct image preview widget for task attachments.
class _DocumentImagePreview extends StatelessWidget {
  final String imageUrl;
  final String fileName;

  const _DocumentImagePreview({
    required this.imageUrl,
    required this.fileName,
  });

  @override
  Widget build(BuildContext context) {
    return _AttachmentDirectPreview(url: imageUrl, fileName: fileName);
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
            child: AppLoadingIndicator(size: 24, color: CareDropTheme.royalBlue),
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
          child: AppLoadingIndicator(size: 28, color: Colors.white),
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





