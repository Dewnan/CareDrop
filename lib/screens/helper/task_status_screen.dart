import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import 'upload_proof_screen.dart';

class TaskStatusScreen extends StatelessWidget {
  const TaskStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<CareDropAppState>();
    final task = appState.activeTask;

    return Scaffold(
      backgroundColor: CareDropTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Active Task',
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
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Elapsed Time Box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                  color: CareDropTheme.royalBlue,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Text(
                      'Time Elapsed',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      appState.formattedTimer,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Progress Timeline Card
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
                      'Progress',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: CareDropTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),

                    _ProgressCheckRow(
                      title: 'Task Accepted',
                      isCompleted: true,
                    ),
                    const SizedBox(height: 14),
                    _ProgressCheckRow(
                      title: 'En Route to Location',
                      isCompleted: true,
                    ),
                    const SizedBox(height: 14),
                    _ProgressCheckRow(
                      title: 'Arrived at ${task?.hospital ?? 'PPUM'}',
                      isCompleted: true,
                    ),
                    const SizedBox(height: 14),
                    _ProgressCheckRow(
                      title: 'Collecting Medication',
                      isCompleted: false,
                      isCurrent: true,
                      currentBadge: 'Now',
                    ),
                    const SizedBox(height: 14),
                    _ProgressCheckRow(
                      title: 'Upload Proof & Complete',
                      isCompleted: false,
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Upload Completion Proof Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CareDropTheme.royalBlue,
                  ),
                  icon: const Icon(Icons.camera_alt_outlined, size: 20),
                  label: const Text(
                    'Upload Completion Proof',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const UploadProofScreen(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressCheckRow extends StatelessWidget {
  final String title;
  final bool isCompleted;
  final bool isCurrent;
  final String? currentBadge;

  const _ProgressCheckRow({
    required this.title,
    required this.isCompleted,
    this.isCurrent = false,
    this.currentBadge,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: isCompleted
                ? const Color(0xFFDCFCE7)
                : isCurrent
                    ? CareDropTheme.royalBlue
                    : const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            isCompleted
                ? Icons.check_rounded
                : isCurrent
                    ? Icons.play_arrow_rounded
                    : Icons.brightness_1,
            size: 14,
            color: isCompleted
                ? CareDropTheme.royalBlue
                : isCurrent
                    ? Colors.white
                    : Colors.transparent,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isCompleted || isCurrent ? FontWeight.bold : FontWeight.normal,
              color: isCompleted || isCurrent ? CareDropTheme.textPrimary : CareDropTheme.textMuted,
            ),
          ),
        ),
        if (currentBadge != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFE6F4F1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              currentBadge!,
              style: const TextStyle(
                color: CareDropTheme.royalBlue,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }
}
