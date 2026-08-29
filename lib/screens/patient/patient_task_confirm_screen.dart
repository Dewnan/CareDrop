import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/task_creation_form_data.dart';
import '../../models/task_model.dart';
import '../../services/task_service.dart';
import '../../services/supabase_storage_service.dart';
import '../../theme/app_theme.dart';
import 'patient_searching_helpers_screen.dart';

/// Screen for reviewing and confirming task details before posting it to Firestore and Supabase Storage.
class PatientTaskConfirmScreen extends StatelessWidget {
  final TaskCreationFormData? formData;
  final String taskTypeName;

  const PatientTaskConfirmScreen({
    super.key,
    this.formData,
    this.taskTypeName = 'Medicine Pickup',
  });

  @override
  Widget build(BuildContext context) {
    final data = formData ?? TaskCreationFormData(taskType: taskTypeName);

    final baseFee = double.tryParse(data.budget ?? '250') ?? 250.0;
    const platformFee = 30.0;
    final totalFee = baseFee + platformFee;

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
                    _buildDetailRow('Pickup', '${data.pickupHospital} (${data.pickupBuilding}, ${data.pickupWard})'),
                    const SizedBox(height: 10),
                    _buildDetailRow('Drop-off', 'Ward ${data.dropoffWard}, Bed ${data.dropoffRoomBed}'),
                    const SizedBox(height: 10),
                    _buildDetailRow('Schedule', data.isAsap ? 'ASAP' : '${data.scheduledDate.toString().split(' ')[0]} ${data.scheduledTime.format(context)}'),
                    const SizedBox(height: 10),
                    _buildDetailRow('Instructions', data.description.isNotEmpty ? data.description : 'None'),
                    if (data.attachmentFileName != null) ...[
                      const SizedBox(height: 10),
                      _buildDetailRow('Attachment', data.attachmentFileName!),
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
                    _buildPriceRow('Service Platform Fee', 'LKR ${platformFee.toStringAsFixed(2)}'),
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
                  ),
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final navigator = Navigator.of(context);
                    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

                    try {
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
                        locationDetail: '${data.pickupBuilding}, ${data.pickupWard}, ${data.pickupRoomBed}',
                        distanceStr: '1.2 km',
                        distanceKm: 1.2,
                        currency: 'LKR',
                        price: totalFee,
                        isUrgent: data.priority == 'Urgent',
                        category: category,
                        deadline: data.isAsap ? 'ASAP' : 'Scheduled',
                        patientInfo: '${data.preferredLanguage} · ${data.preferredGender}',
                        description: data.description,
                        startTimeStr: DateTime.now().toString(),
                        progressStep: TaskProgressStep.pending,
                        proofItems: [
                          ProofItem(title: 'Item Photo', isRequired: true),
                          ProofItem(title: 'Receipt / Handover Signature', isRequired: true),
                        ],
                        attachmentUrl: uploadedDocumentUrl,
                        attachmentFileName: data.attachmentFileName,
                      );

                      final taskId = await TaskService.createTask(newTask);

                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('Task posted to Firestore! Searching for nearby available helpers...'),
                          backgroundColor: Colors.green,
                        ),
                      );

                      if (!context.mounted) return;
                      navigator.push(
                        MaterialPageRoute(
                          builder: (_) => PatientSearchingHelpersScreen(taskId: taskId),
                        ),
                      );
                    } catch (e) {
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text('Failed to post task: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  child: const Text(
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
}
