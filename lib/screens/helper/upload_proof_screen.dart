import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import 'task_complete_confirm_screen.dart';

class UploadProofScreen extends StatefulWidget {
  const UploadProofScreen({super.key});

  @override
  State<UploadProofScreen> createState() => _UploadProofScreenState();
}

class _UploadProofScreenState extends State<UploadProofScreen> {
  bool _item1Done = true;
  bool _item2Done = true;
  bool _item3Done = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CareDropTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Upload Proof',
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
              // Yellow Alert Banner
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF9C3),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFDE047)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Icon(
                      Icons.error_outline_rounded,
                      color: Color(0xFFA16207),
                      size: 20,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Upload clear photos. Patient will review before payment is released.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF854D0E),
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Upload Item 1: Photo of Completed Task
              _UploadCard(
                title: 'Photo of Completed Task',
                subtitle: 'Required',
                isDone: _item1Done,
                icon: Icons.check_circle_outline_rounded,
                onTap: () {
                  setState(() => _item1Done = !_item1Done);
                },
              ),

              const SizedBox(height: 12),

              // Upload Item 2: Receipt / Documentation
              _UploadCard(
                title: 'Receipt / Documentation',
                subtitle: 'Required',
                isDone: _item2Done,
                icon: Icons.check_circle_outline_rounded,
                onTap: () {
                  setState(() => _item2Done = !_item2Done);
                },
              ),

              const SizedBox(height: 12),

              // Upload Item 3: Additional Photo
              _UploadCard(
                title: 'Additional Photo',
                subtitle: 'Optional',
                isDone: _item3Done,
                icon: Icons.camera_alt_outlined,
                onTap: () {
                  setState(() => _item3Done = !_item3Done);
                },
              ),

              const Spacer(),

              // Submit Completion Proof Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CareDropTheme.tealPrimary,
                  ),
                  onPressed: () {
                    context.read<CareDropAppState>().completeActiveTask();
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TaskCompleteConfirmScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    'Submit Completion Proof',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
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
  final IconData icon;
  final VoidCallback onTap;

  const _UploadCard({
    required this.title,
    required this.subtitle,
    required this.isDone,
    required this.icon,
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
            color: isDone ? CareDropTheme.tealPrimary : CareDropTheme.cardBorderColor,
            width: isDone ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isDone ? const Color(0xFFDCFCE7) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: isDone ? CareDropTheme.tealPrimary : CareDropTheme.cardBorderColor),
              ),
              child: Icon(
                isDone ? Icons.check_circle_rounded : icon,
                color: isDone ? CareDropTheme.tealPrimary : CareDropTheme.textMuted,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
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
            if (isDone)
              const Text(
                'Done',
                style: TextStyle(
                  color: CareDropTheme.tealPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              )
            else
              const Icon(
                Icons.upload_file_rounded,
                color: CareDropTheme.textMuted,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
