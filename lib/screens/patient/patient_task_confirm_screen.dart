import 'package:flutter/material.dart';
import '../../models/task_creation_form_data.dart';
import '../../theme/app_theme.dart';
import 'patient_searching_helpers_screen.dart';

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
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 20, color: CareDropTheme.royalBlue),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    const Divider(color: CareDropTheme.cardBorderColor),
                    const SizedBox(height: 12),

                    _buildDetailRow('Description', data.description),
                    const SizedBox(height: 10),
                    if (data.additionalInstructions != null && data.additionalInstructions!.isNotEmpty) ...[
                      _buildDetailRow('Instructions', data.additionalInstructions!),
                      const SizedBox(height: 10),
                    ],
                    _buildDetailRow(
                      'Pickup',
                      '${data.pickupHospital}, ${data.pickupBuilding}, ${data.pickupWard}, ${data.pickupRoomBed}',
                    ),
                    const SizedBox(height: 10),
                    _buildDetailRow(
                      'Drop-off',
                      '${data.dropoffWard}, ${data.dropoffRoomBed}',
                    ),
                    const SizedBox(height: 10),
                    _buildDetailRow(
                      'Schedule',
                      data.isAsap
                          ? 'ASAP — within 30 min'
                          : '${data.scheduledDate.day}/${data.scheduledDate.month}/${data.scheduledDate.year} at ${data.scheduledTime.format(context)}',
                    ),
                    const SizedBox(height: 10),
                    _buildDetailRow('Payment', '${data.paymentMethod} (${data.budget ?? '250'} LKR)'),
                    const SizedBox(height: 10),
                    _buildDetailRow('Preferences', '${data.preferredLanguage} · ${data.preferredGender} · Contact: ${data.contactPreference}'),
                    if (data.attachmentFileName != null) ...[
                      const SizedBox(height: 10),
                      _buildDetailRow('Attachment', data.attachmentFileName!),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Cost Estimate Breakdown Card
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
                      'Cost Estimate',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: CareDropTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _buildPriceRow('Base fee', 'LKR ${baseFee.toStringAsFixed(2)}'),
                    const SizedBox(height: 8),
                    _buildPriceRow('Platform fee', 'LKR ${platformFee.toStringAsFixed(2)}'),
                    const Divider(height: 24, color: CareDropTheme.cardBorderColor),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Estimated Total',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: CareDropTheme.textPrimary,
                          ),
                        ),
                        Text(
                          'LKR ${totalFee.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
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
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Task posted! Searching for nearby available helpers...'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PatientSearchingHelpersScreen(),
                      ),
                    );
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
