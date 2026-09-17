import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class TaskDetailsFormSection extends StatelessWidget {
  final bool isOtherTask;
  final TextEditingController descriptionController;
  final TextEditingController addInstructionsController;
  final bool hasDescriptionError;
  final VoidCallback onDescriptionChanged;

  const TaskDetailsFormSection({
    super.key,
    required this.isOtherTask,
    required this.descriptionController,
    required this.addInstructionsController,
    required this.hasDescriptionError,
    required this.onDescriptionChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '1. TASK DETAILS & DESCRIPTION',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: CareDropTheme.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: CareDropTheme.cardBorderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextField(
                label: isOtherTask ? 'Task Description (Optional)' : 'Task Description *',
                controller: descriptionController,
                required: !isOtherTask,
                hasError: hasDescriptionError,
                maxLines: 3,
                hintText: 'Explain what the helper needs to do...',
                onChanged: (val) => onDescriptionChanged(),
              ),
              const SizedBox(height: 12),
              _buildTextField(
                label: 'Additional Instructions (Optional)',
                controller: addInstructionsController,
                maxLines: 2,
                hintText: 'e.g. Contact upon arrival',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    String? hintText,
    int maxLines = 1,
    bool required = false,
    bool hasError = false,
    Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: hasError ? Colors.red : CareDropTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          onChanged: onChanged,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(color: CareDropTheme.textMuted, fontSize: 13),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: hasError ? Colors.red : CareDropTheme.cardBorderColor,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: hasError ? Colors.red : CareDropTheme.cardBorderColor,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: hasError ? Colors.red : CareDropTheme.royalBlue,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
