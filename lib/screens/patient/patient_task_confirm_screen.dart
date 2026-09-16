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
import '../../services/payment_service.dart';
import '../../services/notification_service.dart';
import '../../services/fcm_notification_service.dart';
import '../../models/notification_model.dart';
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
  State<PatientTaskConfirmScreen> createState() =>
      _PatientTaskConfirmScreenState();
}

class _PatientTaskConfirmScreenState extends State<PatientTaskConfirmScreen> {
  bool _isSubmitting = false;
  late String _selectedPaymentMethod;

  @override
  void initState() {
    super.initState();
    final initialMethod = widget.formData?.paymentMethod ?? '';
    _selectedPaymentMethod = initialMethod.isNotEmpty
        ? initialMethod
        : 'Online Payment (PayHere Card / Mobile Wallet)';
  }

  /// Formats non-empty address components without dangling commas or leading/trailing commas.
  String _formatAddress(List<String?> parts, {String prefix = ''}) {
    final cleanParts = parts
        .where((p) => p != null && p.trim().isNotEmpty && p.trim() != ',')
        .map((p) => p!.trim())
        .toList();
    if (cleanParts.isEmpty) {
      return prefix.isNotEmpty ? prefix : 'Location specified';
    }
    return prefix.isNotEmpty
        ? '$prefix: ${cleanParts.join(', ')}'
        : cleanParts.join(', ');
  }

  /// Calculates dynamic distance between pickup and dropoff coordinates if present, or returns default estimated distance.
  double _calculateDistanceKm(TaskCreationFormData data) {
    if (data.pickupLat != null &&
        data.pickupLng != null &&
        data.dropoffLat != null &&
        data.dropoffLng != null) {
      const p = 0.017453292519943295; // Pi / 180
      final a =
          0.5 -
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

  /// Handles task creation request with duplicate submission prevention, PayHere payment processing, and storage upload.
  Future<void> _handlePostTask({
    required TaskCreationFormData data,
    required String pickupAddress,
    required String dropoffAddress,
    required String scheduleDisplay,
    required double totalFee,
  }) async {
    if (_isSubmitting) return;

    final requiresPickup = data.taskType != 'Other';
    final requiresDropoff =
        data.taskType == 'Medicine Pickup' ||
        data.taskType == 'Pharmacy Purchase' ||
        data.taskType == 'Document Delivery';

    if (requiresPickup && (data.pickupLat == null || data.pickupLng == null)) {
      FeedbackBanner.show(
        context,
        message:
            'Pickup location coordinates are missing. Please pin location on map.',
        type: FeedbackType.error,
      );
      return;
    }

    if (requiresDropoff &&
        (data.dropoffLat == null || data.dropoffLng == null)) {
      FeedbackBanner.show(
        context,
        message:
            'Drop-off location coordinates are missing. Please pin location on map.',
        type: FeedbackType.error,
      );
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
        if (data.localAttachmentPath != null &&
            data.localAttachmentPath!.isNotEmpty) {
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

      String? payherePaymentId;
      final isPayHere =
          _selectedPaymentMethod.toLowerCase().contains('payhere') ||
          _selectedPaymentMethod.toLowerCase().contains('card') ||
          _selectedPaymentMethod.toLowerCase().contains('online') ||
          _selectedPaymentMethod.toLowerCase().contains('escrow');

      if (isPayHere) {
        if (!mounted) return;
        final appState = context.read<CareDropAppState>();
        final currentUser = FirebaseAuth.instance.currentUser;

        final tempOrderId = 'ORD_${DateTime.now().millisecondsSinceEpoch}';
        final userEmail =
            appState.currentUserModel?.email ??
            currentUser?.email ??
            'patient@caredrop.lk';
        final userPhone =
            appState.currentUserModel?.phone ??
            currentUser?.phoneNumber ??
            '+94770000000';

        final customerName =
            appState.currentUserModel?.fullName.isNotEmpty == true
            ? appState.currentUserModel!.fullName
            : (currentUser?.displayName?.isNotEmpty == true
                  ? currentUser!.displayName!
                  : 'Patient');

        try {
          payherePaymentId = await PaymentService.processSimulatedPayment(
            orderId: tempOrderId,
            amount: totalFee,
            taskTitle: data.taskType,
            customerName: customerName,
            customerEmail: userEmail,
            customerPhone: userPhone,
            currency: 'LKR',
          );
        } catch (payErr) {
          final cleanErr = payErr.toString().replaceAll('Exception: ', '');
          await NotificationService.sendNotification(
            userId: currentUserId,
            title: 'Payment Failed',
            message: 'Simulated payment issue: $cleanErr',
            type: NotificationType.payment,
          );

          if (mounted) {
            FeedbackBanner.show(
              context,
              message: 'Payment Error: $cleanErr',
              type: FeedbackType.error,
              duration: const Duration(seconds: 5),
            );
          }
          setState(() => _isSubmitting = false);
          return;
        }

        if (payherePaymentId == null) {
          if (mounted) {
            FeedbackBanner.show(
              context,
              message: 'Payment was canceled or failed.',
              type: FeedbackType.warning,
            );
          }
          setState(() => _isSubmitting = false);
          return;
        }
      }

      final category = TaskCategory.values.firstWhere(
        (e) =>
            e.name.toLowerCase() ==
            data.taskType.toLowerCase().replaceAll(' ', ''),
        orElse: () => TaskCategory.medicine,
      );

      final newTask = TaskModel(
        id: '',
        patientId: currentUserId,
        title: data.taskType,
        pickupAddress: pickupAddress.isNotEmpty ? pickupAddress : data.pickupHospital,
        pickupLat: data.pickupLat,
        pickupLng: data.pickupLng,
        dropoffAddress: dropoffAddress.isNotEmpty ? dropoffAddress : null,
        dropoffLat: data.dropoffLat,
        dropoffLng: data.dropoffLng,
        roomDetail: dropoffAddress.isNotEmpty ? dropoffAddress : pickupAddress,
        currency: 'LKR',
        price: totalFee,
        isUrgent: data.priority == 'Urgent',
        category: category,
        deadline: scheduleDisplay,
        description: data.description,
        progressStep: TaskProgressStep.pending,
        proofItems: [
          ProofItem(title: 'Item Photo', isRequired: true),
          ProofItem(title: 'Receipt / Handover Signature', isRequired: true),
        ],
        attachmentUrl: uploadedDocumentUrl,
        attachmentFileName: data.attachmentFileName,
        serviceDuration: data.taskType == 'Patient Caregiver'
            ? data.serviceDuration
            : null,
        preferredGender: data.taskType == 'Patient Caregiver'
            ? data.preferredGender
            : null,
        preferredLanguage: data.taskType == 'Patient Caregiver'
            ? data.preferredLanguage
            : null,
        itemName: data.itemName,
        itemQuantity: data.itemQuantity,
        itemSpecialInstructions: data.itemSpecialInstructions,
        paymentMethod: _selectedPaymentMethod,
        payherePaymentId: payherePaymentId,
        contactPreference: data.contactPreference,
      );

      final taskId = await TaskService.createTask(newTask);

      // Save payment success / task created notification
      await NotificationService.sendNotification(
        userId: currentUserId,
        title: isPayHere ? 'Payment Held in Escrow' : 'Task Posted',
        message: isPayHere
            ? 'LKR ${totalFee.toStringAsFixed(2)} held safely in Escrow for ${data.taskType}.'
            : 'Task ${data.taskType} created successfully.',
        type: NotificationType.payment,
        relatedTaskId: taskId,
      );
      
      // Request Just-In-Time notification permissions so patient gets alerts when helper accepts
      await FcmNotificationService.registerFcmToken(uid: currentUserId);

      if (!mounted) return;
      FeedbackBanner.show(
        context,
        message: isPayHere
            ? 'Online Escrow payment held securely! Searching for nearby helpers...'
            : 'Task posted successfully! Searching for nearby available helpers...',
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
    final data =
        widget.formData ?? TaskCreationFormData(taskType: widget.taskTypeName);

    final isCashPayment = _selectedPaymentMethod.toLowerCase().contains('cash');
    final baseFee = double.tryParse(data.budget ?? '250') ?? 250.0;
    // Exclude service platform fee for Cash on Delivery
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
    final dateStr =
        '${data.scheduledDate.year}-${data.scheduledDate.month.toString().padLeft(2, '0')}-${data.scheduledDate.day.toString().padLeft(2, '0')}';
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
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 20,
            color: CareDropTheme.textPrimary,
          ),
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
                          child: const Icon(
                            Icons.inventory_2_outlined,
                            color: CareDropTheme.royalBlue,
                            size: 22,
                          ),
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
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
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
                    if (dropoffAddress.isNotEmpty &&
                        dropoffAddress != pickupAddress) ...[
                      const SizedBox(height: 10),
                      _buildDetailRow('Drop-off', dropoffAddress),
                    ],
                    if (!data.isAsap &&
                        data.priority != 'Urgent' &&
                        data.priority != 'ASAP') ...[
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
                    if (data.itemQuantity != null &&
                        data.itemQuantity!.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      _buildDetailRow('Quantity', data.itemQuantity!),
                    ],
                    if (data.itemSpecialInstructions != null &&
                        data.itemSpecialInstructions!.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      _buildDetailRow(
                        'Item Notes',
                        data.itemSpecialInstructions!,
                      ),
                    ],
                    if (data.taskType == 'Patient Caregiver') ...[
                      const SizedBox(height: 10),
                      _buildDetailRow('Duration', data.serviceDuration),
                      const SizedBox(height: 10),
                      _buildDetailRow('Gender Pref.', data.preferredGender),
                      const SizedBox(height: 10),
                      _buildDetailRow('Language Req.', data.preferredLanguage),
                    ],
                    if (data.attachmentFileName != null ||
                        data.localAttachmentPath != null ||
                        data.attachmentBytes != null ||
                        data.attachmentUrl != null) ...[
                      _buildAttachmentPreview(data),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Payment Method Selector card
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
                      'SELECT PAYMENT METHOD',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: CareDropTheme.royalBlue,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () => setState(
                        () => _selectedPaymentMethod = 'Online Payment',
                      ),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color:
                              _selectedPaymentMethod.toLowerCase().contains(
                                    'payhere',
                                  ) ||
                                  _selectedPaymentMethod.toLowerCase().contains(
                                    'online',
                                  ) ||
                                  _selectedPaymentMethod.toLowerCase().contains(
                                    'card',
                                  )
                              ? const Color(0xFFEFF6FF)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color:
                                _selectedPaymentMethod.toLowerCase().contains(
                                      'payhere',
                                    ) ||
                                    _selectedPaymentMethod
                                        .toLowerCase()
                                        .contains('online') ||
                                    _selectedPaymentMethod
                                        .toLowerCase()
                                        .contains('card')
                                ? CareDropTheme.royalBlue
                                : CareDropTheme.cardBorderColor,
                            width:
                                _selectedPaymentMethod.toLowerCase().contains(
                                      'payhere',
                                    ) ||
                                    _selectedPaymentMethod
                                        .toLowerCase()
                                        .contains('online') ||
                                    _selectedPaymentMethod
                                        .toLowerCase()
                                        .contains('card')
                                ? 1.5
                                : 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.payment,
                              color: CareDropTheme.royalBlue,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Online Payment (Demo Card)',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: CareDropTheme.textPrimary,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Instant simulated card authorization held in Escrow',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: CareDropTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Radio<String>(
                              value:
                                  'Online Payment',
                              groupValue: _selectedPaymentMethod,
                              activeColor: CareDropTheme.royalBlue,
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _selectedPaymentMethod = val);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => setState(
                        () => _selectedPaymentMethod = 'Cash on Delivery',
                      ),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color:
                              _selectedPaymentMethod.toLowerCase().contains(
                                'cash',
                              )
                              ? const Color(0xFFEFF6FF)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color:
                                _selectedPaymentMethod.toLowerCase().contains(
                                  'cash',
                                )
                                ? CareDropTheme.royalBlue
                                : CareDropTheme.cardBorderColor,
                            width:
                                _selectedPaymentMethod.toLowerCase().contains(
                                  'cash',
                                )
                                ? 1.5
                                : 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.payments_outlined,
                              color: CareDropTheme.royalBlue,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Cash on Delivery',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: CareDropTheme.textPrimary,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Pay cash directly to helper upon task handover',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: CareDropTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Radio<String>(
                              value: 'Cash on Delivery',
                              groupValue: _selectedPaymentMethod,
                              activeColor: CareDropTheme.royalBlue,
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _selectedPaymentMethod = val);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
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
                    _buildPriceRow(
                      'Offered Budget',
                      'LKR ${baseFee.toStringAsFixed(2)}',
                    ),
                    const SizedBox(height: 8),
                    _buildPriceRow('Payment Method', _selectedPaymentMethod),
                    const SizedBox(height: 8),
                    _buildPriceRow(
                      'Service Platform Fee',
                      isCashPayment
                          ? 'LKR 0.00 (Cash)'
                          : 'LKR ${platformFee.toStringAsFixed(2)}',
                    ),

                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Amount',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
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
                    disabledBackgroundColor: CareDropTheme.royalBlue.withValues(
                      alpha: 0.5,
                    ),
                  ),
                  onPressed: _isSubmitting
                      ? null
                      : () => _handlePostTask(
                          data: data,
                          pickupAddress: pickupAddress,
                          dropoffAddress: dropoffAddress,
                          scheduleDisplay: scheduleDisplay,
                          totalFee: totalFee,
                        ),
                  child: _isSubmitting
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AppLoadingIndicator(size: 20, color: Colors.white),
                            SizedBox(width: 12),
                            Text(
                              'Posting Task...',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        )
                      : const Text(
                          'Post Task',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
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
            style: const TextStyle(
              color: CareDropTheme.textMuted,
              fontSize: 12,
            ),
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

  /// Renders a single row in the payment summary table with label and right-aligned price or detail text.
  Widget _buildPriceRow(String label, String price) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: CareDropTheme.textSecondary,
            fontSize: 13,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            price,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: CareDropTheme.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  /// Displays visual preview thumbnail or document file badge for attached task documents.
  Widget _buildAttachmentPreview(TaskCreationFormData data) {
    Widget imageWidget;
    if (data.localAttachmentPath != null &&
        data.localAttachmentPath!.isNotEmpty) {
      final file = File(data.localAttachmentPath!);
      if (file.existsSync()) {
        imageWidget = Image.file(
          file,
          height: 140,
          width: double.infinity,
          fit: BoxFit.cover,
        );
      } else {
        imageWidget = const Icon(
          Icons.insert_drive_file_outlined,
          size: 40,
          color: CareDropTheme.royalBlue,
        );
      }
    } else if (data.attachmentBytes != null) {
      imageWidget = Image.memory(
        data.attachmentBytes,
        height: 140,
        width: double.infinity,
        fit: BoxFit.cover,
      );
    } else if (data.attachmentUrl != null && data.attachmentUrl!.isNotEmpty) {
      imageWidget = Image.network(
        data.attachmentUrl!,
        height: 140,
        width: double.infinity,
        fit: BoxFit.cover,
      );
    } else {
      imageWidget = const Icon(
        Icons.insert_drive_file_outlined,
        size: 40,
        color: CareDropTheme.royalBlue,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        const Text(
          'Attachment',
          style: TextStyle(color: CareDropTheme.textMuted, fontSize: 12),
        ),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  child: Text(
                    data.attachmentFileName!,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: CareDropTheme.textPrimary,
                    ),
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
