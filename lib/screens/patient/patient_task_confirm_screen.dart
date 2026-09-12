import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../models/task_creation_form_data.dart';
import '../../models/task_model.dart';
import '../../providers/app_state.dart';
import '../../services/task_service.dart';
import '../../services/supabase_storage_service.dart';
import '../../theme/app_theme.dart';
import '../../components/feedback_banner.dart';
import '../../components/loading_indicator.dart';
import 'patient_searching_helpers_screen.dart';

/// Screen for reviewing and confirming task details before posting it to Firestore and Supabase Storage.
class PatientTaskConfirmScreen extends StatefulWidget {
  final TaskCreationFormData? formData;
  final String taskTypeName;

  const PatientTaskConfirmScreen({
    super.key,
    this.formData,
    this.taskTypeName = 'Medicine Pickup',
  });

  @override
  State<PatientTaskConfirmScreen> createState() => _PatientTaskConfirmScreenState();
}

class _PatientTaskConfirmScreenState extends State<PatientTaskConfirmScreen> {
  bool _isSubmitting = false;

  /// Formats non-empty address components without dangling commas or leading/trailing commas.
  String _formatAddress(List<String?> parts, {String prefix = ''}) {
    final cleanParts = parts
        .where((p) => p != null && p.trim().isNotEmpty && p.trim() != ',')
        .map((p) => p!.trim())
        .toList();
    if (cleanParts.isEmpty) return prefix.isNotEmpty ? prefix : 'Location specified';
    return prefix.isNotEmpty ? '$prefix: ${cleanParts.join(', ')}' : cleanParts.join(', ');
  }

  /// Calculates dynamic distance between pickup and dropoff coordinates if present, or returns default estimated distance.
  double _calculateDistanceKm(TaskCreationFormData data) {
    if (data.pickupLat != null && data.pickupLng != null && data.dropoffLat != null && data.dropoffLng != null) {
      const p = 0.017453292519943295; // Pi / 180
      final a = 0.5 -
          math.cos((data.dropoffLat! - data.pickupLat!) * p) / 2 +
          math.cos(data.pickupLat! * p) *
              math.cos(data.dropoffLat! * p) *
              (1 - math.cos((data.dropoffLng! - data.pickupLng!) * p)) /
              2;
      final km = 12742 * math.asin(math.sqrt(a)); // 2 * R * asin(...)
      return double.parse(km.toStringAsFixed(1));
    }
    return 1.5;
  }

  /// Handles task creation request with duplicate submission prevention and storage upload.
  Future<void> _handlePostTask({
    required TaskCreationFormData data,
    required String pickupAddress,
    required String dropoffAddress,
    required String scheduleDisplay,
    required String distanceStr,
    required double distanceKm,
    required String requesterName,
    required double totalFee,
  }) async {
    if (_isSubmitting) return;

    final requiresPickup = data.taskType != 'Other';
    final requiresDropoff = data.taskType == 'Medicine Pickup' ||
        data.taskType == 'Pharmacy Purchase' ||
        data.taskType == 'Document Delivery';

    if (requiresPickup && (data.pickupLat == null || data.pickupLng == null)) {
      FeedbackBanner.show(context, message: 'Pickup location coordinates are missing. Please pin location on map.', type: FeedbackType.error);
      return;
    }

    if (requiresDropoff && (data.dropoffLat == null || data.dropoffLng == null)) {
      FeedbackBanner.show(context, message: 'Drop-off location coordinates are missing. Please pin location on map.', type: FeedbackType.error);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final navigator = Navigator.of(context);
      final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

      String? uploadedDocumentUrl = data.attachmentUrl;

      // Upload attachment file/bytes to Supabase Storage if attached and not yet uploaded
      if (uploadedDocumentUrl == null && data.attachmentFileName != null) {
        final storageService = SupabaseStorageService();
        if (data.localAttachmentPath != null && data.localAttachmentPath!.isNotEmpty) {
          final file = File(data.localAttachmentPath!);
          uploadedDocumentUrl = await storageService.uploadDocument(
            file: file,
            userId: currentUserId.isNotEmpty ? currentUserId : 'guest',
            fileName: data.attachmentFileName!,
          );
        } else if (data.attachmentBytes != null) {
          uploadedDocumentUrl = await storageService.uploadDocumentBytes(
            bytes: data.attachmentBytes,
            userId: currentUserId.isNotEmpty ? currentUserId : 'guest',
            fileName: data.attachmentFileName!,
          );
        }
      }

      final category = TaskCategory.values.firstWhere(
        (e) => e.name.toLowerCase() == data.taskType.toLowerCase().replaceAll(' ', ''),
        orElse: () => TaskCategory.medicine,
      );

      final newTask = TaskModel(
        id: '',
        patientId: currentUserId,
        title: data.taskType,
        hospital: data.pickupHospital,
        locationDetail: dropoffAddress.isNotEmpty ? dropoffAddress : pickupAddress,
        pickupAddress: pickupAddress.isNotEmpty ? pickupAddress : null,
        pickupLat: data.pickupLat,
        pickupLng: data.pickupLng,
        dropoffAddress: dropoffAddress.isNotEmpty ? dropoffAddress : null,
        dropoffLat: data.dropoffLat,
        dropoffLng: data.dropoffLng,
        distanceStr: distanceStr,
        distanceKm: distanceKm,
        currency: 'LKR',
        price: totalFee,
        isUrgent: data.priority == 'Urgent',
        category: category,
        deadline: scheduleDisplay,
        patientInfo: requesterName,
        description: data.description,
        startTimeStr: DateTime.now().toString(),
        progressStep: TaskProgressStep.pending,
        proofItems: [
          ProofItem(title: 'Item Photo', isRequired: true),
          ProofItem(title: 'Receipt / Handover Signature', isRequired: true),
        ],
        attachmentUrl: uploadedDocumentUrl,
        attachmentFileName: data.attachmentFileName,
        serviceDuration: data.taskType == 'Patient Caregiver' ? data.serviceDuration : null,
        preferredGender: data.taskType == 'Patient Caregiver' ? data.preferredGender : null,
        preferredLanguage: data.taskType == 'Patient Caregiver' ? data.preferredLanguage : null,
        itemName: data.itemName,
        itemQuantity: data.itemQuantity,
        itemSpecialInstructions: data.itemSpecialInstructions,
        paymentMethod: data.paymentMethod,
        contactPreference: data.contactPreference,
      );

      final taskId = await TaskService.createTask(newTask);

      if (!mounted) return;
      FeedbackBanner.show(
        context,
        message: 'Task posted successfully! Searching for nearby available helpers...',
        type: FeedbackType.success,
      );

      navigator.push(
        MaterialPageRoute(
          builder: (_) => PatientSearchingHelpersScreen(taskId: taskId),
        ),
      );
    } catch (e) {
      if (mounted) {
        FeedbackBanner.show(
          context,
          message: 'Failed to post task: $e',
          type: FeedbackType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.formData ?? TaskCreationFormData(taskType: widget.taskTypeName);
    final appState = context.watch<CareDropAppState>();
    User? firebaseUser;
    try {
      firebaseUser = FirebaseAuth.instance.currentUser;
    } catch (_) {}
    final requesterName = (appState.currentUserModel?.fullName.isNotEmpty == true)
        ? appState.currentUserModel!.fullName
        : (firebaseUser?.displayName?.isNotEmpty == true
            ? firebaseUser!.displayName!
            : 'Patient');

    final isCashPayment = data.paymentMethod.toLowerCase().contains('cash');
    final baseFee = double.tryParse(data.budget ?? '250') ?? 250.0;
    // Exclude service platform fee for Cash on Delivery per requirement 6
    final platformFee = isCashPayment ? 0.0 : 30.0;
    final totalFee = baseFee + platformFee;

    // Clean address strings per requirement 2
    final pickupAddress = _formatAddress([
      data.pickupHospital,
      data.pickupBuilding,
      data.pickupWard,
      data.pickupRoomBed,
    ]);

    final dropoffAddress = _formatAddress([
      data.dropoffWard.isNotEmpty ? data.dropoffWard : null,
      data.dropoffRoomBed.isNotEmpty ? data.dropoffRoomBed : null,
    ]);

    // Schedule string per requirements 3 & 4
    final dateStr = '${data.scheduledDate.year}-${data.scheduledDate.month.toString().padLeft(2, '0')}-${data.scheduledDate.day.toString().padLeft(2, '0')}';
    final timeStr = data.scheduledTime.format(context);
    final scheduleDisplay = '$dateStr at $timeStr';

    final distanceKm = _calculateDistanceKm(data);
    final distanceStr = '$distanceKm km';

    return Scaffold(
      backgroundColor: CareDropTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: CareDropTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Review & Confirm Task',
          style: TextStyle(
            color: CareDropTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Task details card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: CareDropTheme.cardBorderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.inventory_2_outlined, color: CareDropTheme.royalBlue, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data.taskType,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: CareDropTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: data.priority == 'Urgent'
                                      ? const Color(0xFFFEE2E2)
                                      : const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  data.priority,
                                  style: TextStyle(
                                    color: data.priority == 'Urgent'
                                        ? const Color(0xFFEF4444)
                                        : CareDropTheme.royalBlue,
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
                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 16),
                    _buildDetailRow('Pickup', pickupAddress),
                    if (dropoffAddress.isNotEmpty && dropoffAddress != pickupAddress) ...[
                      const SizedBox(height: 10),
                      _buildDetailRow('Drop-off', dropoffAddress),
                    ],
                    if (!data.isAsap && data.priority != 'Urgent' && data.priority != 'ASAP') ...[
                      const SizedBox(height: 10),
                      _buildDetailRow('Schedule', scheduleDisplay),
                    ],
                    const SizedBox(height: 10),
                    _buildDetailRow('Distance', distanceStr),
                    if (data.description.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      _buildDetailRow('Description', data.description),
                    ],
                    if (data.itemName != null && data.itemName!.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      _buildDetailRow('Item / Medicine', data.itemName!),
                    ],
                    if (data.itemQuantity != null && data.itemQuantity!.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      _buildDetailRow('Quantity', data.itemQuantity!),
                    ],
                    if (data.itemSpecialInstructions != null && data.itemSpecialInstructions!.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      _buildDetailRow('Item Notes', data.itemSpecialInstructions!),
                    ],
                    if (data.taskType == 'Patient Caregiver') ...[
                      const SizedBox(height: 10),
                      _buildDetailRow('Duration', data.serviceDuration),
                      const SizedBox(height: 10),
                      _buildDetailRow('Gender Pref.', data.preferredGender),
                      const SizedBox(height: 10),
                      _buildDetailRow('Language Req.', data.preferredLanguage),
                    ],
                    if (data.attachmentFileName != null || data.localAttachmentPath != null || data.attachmentBytes != null || data.attachmentUrl != null) ...[
                      _buildAttachmentPreview(data),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Fee summary card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: CareDropTheme.cardBorderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PAYMENT SUMMARY',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: CareDropTheme.royalBlue,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildPriceRow('Offered Budget', 'LKR ${baseFee.toStringAsFixed(2)}'),
                    const SizedBox(height: 8),
                    _buildPriceRow('Payment Method', data.paymentMethod),
                    const SizedBox(height: 8),
                    _buildPriceRow(
                      'Service Platform Fee',
                      isCashPayment ? 'LKR 0.00 (Cash)' : 'LKR ${platformFee.toStringAsFixed(2)}',
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Amount', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        Text(
                          'LKR ${totalFee.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: CareDropTheme.royalBlue,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Post Task Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CareDropTheme.royalBlue,
                    disabledBackgroundColor: CareDropTheme.royalBlue.withValues(alpha: 0.5),
                  ),
                  onPressed: _isSubmitting
                      ? null
                      : () => _handlePostTask(
                            data: data,
                            pickupAddress: pickupAddress,
                            dropoffAddress: dropoffAddress,
                            scheduleDisplay: scheduleDisplay,
                            distanceStr: distanceStr,
                            distanceKm: distanceKm,
                            requesterName: requesterName,
                            totalFee: totalFee,
                          ),
                  child: _isSubmitting
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AppLoadingIndicator(size: 20, color: Colors.white),
                            SizedBox(width: 12),
                            Text(
                              'Posting Task...',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                            ),
                          ],
                        )
                      : const Text(
                          'Post Task',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: const TextStyle(color: CareDropTheme.textMuted, fontSize: 12),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: CareDropTheme.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPriceRow(String label, String price) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: CareDropTheme.textSecondary, fontSize: 13)),
        Text(price, style: const TextStyle(color: CareDropTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
      ],
    );
  }

  /// Displays visual preview thumbnail or document file badge for attached task documents.
  Widget _buildAttachmentPreview(TaskCreationFormData data) {
    Widget imageWidget;
    if (data.localAttachmentPath != null && data.localAttachmentPath!.isNotEmpty) {
      final file = File(data.localAttachmentPath!);
      if (file.existsSync()) {
        imageWidget = Image.file(file, height: 140, width: double.infinity, fit: BoxFit.cover);
      } else {
        imageWidget = const Icon(Icons.insert_drive_file_outlined, size: 40, color: CareDropTheme.royalBlue);
      }
    } else if (data.attachmentBytes != null) {
      imageWidget = Image.memory(data.attachmentBytes, height: 140, width: double.infinity, fit: BoxFit.cover);
    } else if (data.attachmentUrl != null && data.attachmentUrl!.isNotEmpty) {
      imageWidget = Image.network(data.attachmentUrl!, height: 140, width: double.infinity, fit: BoxFit.cover);
    } else {
      imageWidget = const Icon(Icons.insert_drive_file_outlined, size: 40, color: CareDropTheme.royalBlue);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        const Text('Attachment', style: TextStyle(color: CareDropTheme.textMuted, fontSize: 12)),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: CareDropTheme.cardBorderColor),
            color: Colors.grey.shade50,
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              imageWidget,
              if (data.attachmentFileName != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Text(
                    data.attachmentFileName!,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: CareDropTheme.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

