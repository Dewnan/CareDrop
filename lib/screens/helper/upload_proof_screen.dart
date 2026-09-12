import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../components/document_picker.dart';
import '../../models/task_model.dart';
import '../../providers/app_state.dart';
import '../../services/task_service.dart';
import '../../theme/app_theme.dart';
import '../../components/loading_indicator.dart';
import 'task_complete_confirm_screen.dart';

/// Renders trip completion screen allowing helpers to upload a receipt/documentation and add optional trip notes.
class UploadProofScreen extends StatefulWidget {
  const UploadProofScreen({super.key});

  @override
  State<UploadProofScreen> createState() => _UploadProofScreenState();
}

class _UploadProofScreenState extends State<UploadProofScreen> {
  PickedFileData? _attachedReceipt;
  final TextEditingController _notesController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  /// Prompts user to pick a receipt image or document via shared document picker modal sheet.
  Future<void> _handlePickReceipt() async {
    final picked = await showDocumentPicker(context);
    if (picked != null && mounted) {
      setState(() {
        _attachedReceipt = picked;
      });
    }
  }

  /// Completes active task in Firestore and app state, then redirects to task completion confirmation screen.
  Future<void> _handleCompleteTrip() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    final appState = context.read<CareDropAppState>();
    final activeTask = appState.activeTask;

    if (activeTask != null) {
      try {
        await TaskService.updateTaskProgress(
          taskId: activeTask.id,
          step: TaskProgressStep.completed,
          helperName: appState.currentUserModel?.fullName ?? appState.helperUser.fullName,
        );
      } catch (_) {}
    }

    appState.completeActiveTask();

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const TaskCompleteConfirmScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasAttachment = _attachedReceipt != null;

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
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Info Banner
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: CareDropTheme.royalBlue.withValues(alpha: 0.3),
                          ),
                        ),
                        child: const Text(
                          'Receipt or document upload is optional depending on your task agreement with the patient.',
                          style: TextStyle(
                            fontSize: 13,
                            color: CareDropTheme.textPrimary,
                            height: 1.35,
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Single Upload Section: Add Receipt
                      const Text(
                        'Receipt / Proof Document',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: CareDropTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),

                      _UploadCard(
                        title: 'Add Receipt / Documentation',
                        subtitle: hasAttachment
                            ? _attachedReceipt!.name
                            : 'Optional - Upload photo or PDF receipt',
                        isDone: hasAttachment,
                        onTap: _handlePickReceipt,
                        onRemove: hasAttachment
                            ? () {
                                setState(() => _attachedReceipt = null);
                              }
                            : null,
                      ),

                      const SizedBox(height: 24),

                      // Additional Notes Text Box
                      const Text(
                        'Additional Notes (Optional)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: CareDropTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),

                      TextField(
                        controller: _notesController,
                        maxLines: 4,
                        style: const TextStyle(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Enter any additional details or notes about this trip...',
                          hintStyle: const TextStyle(
                            color: CareDropTheme.textMuted,
                            fontSize: 13,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.all(14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: CareDropTheme.cardBorderColor,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: CareDropTheme.cardBorderColor,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: CareDropTheme.royalBlue,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Complete Trip & Finish Action Button with Debounce
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
                  onPressed: _isSubmitting ? null : _handleCompleteTrip,
                  child: _isSubmitting
                      ? const AppLoadingIndicator(size: 20, color: Colors.white)
                      : const Text(
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

/// Renders a single upload card with attachment state, custom image icon, and action button.
class _UploadCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isDone;
  final VoidCallback onTap;
  final VoidCallback? onRemove;

  const _UploadCard({
    required this.title,
    required this.subtitle,
    required this.isDone,
    required this.onTap,
    this.onRemove,
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
            Container(
              width: 42,
              height: 42,
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: isDone ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Image.asset(
                'assets/images/attachment_icon.png',
                fit: BoxFit.contain,
                errorBuilder: (ctx, err, stack) => Icon(
                  Icons.receipt_long,
                  color: isDone ? CareDropTheme.royalBlue : CareDropTheme.textMuted,
                  size: 24,
                ),
              ),
            ),
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDone ? CareDropTheme.royalBlue : CareDropTheme.textMuted,
                      fontWeight: isDone ? FontWeight.w500 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (isDone && onRemove != null)
              IconButton(
                icon: const Icon(Icons.close, size: 20, color: Colors.red),
                onPressed: onRemove,
                tooltip: 'Remove receipt',
              )
            else
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
