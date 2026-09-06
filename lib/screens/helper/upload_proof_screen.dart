import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import 'task_complete_confirm_screen.dart';

/// Renders trip completion screen allowing helpers to upload optional task photos/receipts or complete the trip directly.
class UploadProofScreen extends StatefulWidget {
  const UploadProofScreen({super.key});

  @override
  State<UploadProofScreen> createState() => _UploadProofScreenState();
}

class _UploadProofScreenState extends State<UploadProofScreen> {
  bool _item1Done = false;
  bool _item2Done = false;

  /// Completes active task in app state and redirects to task completion confirmation screen.
  void _handleCompleteTrip() {
    context.read<CareDropAppState>().completeActiveTask();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const TaskCompleteConfirmScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CareDropTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Complete Trip',
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
              // Info Banner
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: CareDropTheme.royalBlue.withValues(alpha: 0.3)),
                ),
                child: const Text(
                  'Proof photos or receipt uploads are optional depending on your task agreement with the patient.',
                  style: TextStyle(
                    fontSize: 13,
                    color: CareDropTheme.textPrimary,
                    height: 1.35,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Upload Item 1: Photo of Completed Task (Optional)
              _UploadCard(
                title: 'Photo of Completed Delivery / Task',
                subtitle: 'Optional - Upload if required by task',
                isDone: _item1Done,
                onTap: () {
                  setState(() => _item1Done = !_item1Done);
                },
              ),

              const SizedBox(height: 12),

              // Upload Item 2: Receipt / Documentation (Optional)
              _UploadCard(
                title: 'Receipt / Medical Documentation',
                subtitle: 'Optional - Upload if required by task',
                isDone: _item2Done,
                onTap: () {
                  setState(() => _item2Done = !_item2Done);
                },
              ),

              const Spacer(),

              // Complete Trip & Finish Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CareDropTheme.royalBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _handleCompleteTrip,
                  child: const Text(
                    'Complete Trip & Finish',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
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
}

class _UploadCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isDone;
  final VoidCallback onTap;

  const _UploadCard({
    required this.title,
    required this.subtitle,
    required this.isDone,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDone ? const Color(0xFFF0FDF4) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDone ? CareDropTheme.royalBlue : CareDropTheme.cardBorderColor,
            width: isDone ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: CareDropTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: CareDropTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isDone ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                isDone ? 'Attached' : '+ Add',
                style: TextStyle(
                  color: isDone ? CareDropTheme.royalBlue : CareDropTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
