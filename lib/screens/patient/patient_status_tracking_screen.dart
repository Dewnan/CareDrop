import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'patient_review_proof_screen.dart';

/// Renders real-time task status timeline for patients tracking helper progress.
class PatientStatusTrackingScreen extends StatelessWidget {
  final String? taskId;

  const PatientStatusTrackingScreen({
    super.key,
    this.taskId,
  });

  @override
  Widget build(BuildContext context) {
    if (taskId != null && taskId!.isNotEmpty) {
      return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('tasks').doc(taskId).snapshots(),
        builder: (context, snapshot) {
          final taskData = snapshot.data?.data();
          final progressStep = taskData?['progressStep'] as String? ?? 'taskAccepted';
          final title = taskData?['title'] as String? ?? 'CareDrop Task';

          final isAccepted = progressStep != 'pending';
          final isEnRoutePickup = progressStep == 'taskAccepted' || progressStep == 'enRoute';
          final isPickupConfirmed = progressStep == 'arrivedAtLocation' ||
              progressStep == 'inProgress' ||
              progressStep == 'uploadProof';
          final isCompleted = progressStep == 'completed';

          return _buildContent(
            context,
            taskTitle: title,
            statusBadge: isCompleted
                ? 'Completed'
                : isPickupConfirmed
                    ? 'Package / Patient Picked Up'
                    : 'Helper En Route to Pickup',
            isAccepted: isAccepted,
            isEnRoutePickup: isEnRoutePickup,
            isPickupConfirmed: isPickupConfirmed,
            isCompleted: isCompleted,
          );
        },
      );
    }

    return _buildContent(
      context,
      taskTitle: 'Medication Pickup',
      statusBadge: 'In Progress',
      isAccepted: true,
      isEnRoutePickup: false,
      isPickupConfirmed: true,
      isCompleted: false,
    );
  }

  /// Builds body content for task progress tracking timeline.
  Widget _buildContent(
    BuildContext context, {
    required String taskTitle,
    required String statusBadge,
    required bool isAccepted,
    required bool isEnRoutePickup,
    required bool isPickupConfirmed,
    required bool isCompleted,
  }) {
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
          'Task Status',
          style: TextStyle(
            color: CareDropTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
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
                          child: const Icon(Icons.inventory_2_outlined, color: CareDropTheme.tealPrimary, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                taskTitle,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: CareDropTheme.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isCompleted
                                      ? const Color(0xFFDCFCE7)
                                      : const Color(0xFFFEF3C7),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  statusBadge,
                                  style: TextStyle(
                                    color: isCompleted ? const Color(0xFF16A34A) : const Color(0xFFD97706),
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

                    const SizedBox(height: 24),

                    // Progress timeline items
                    _buildTimelineStep(
                      title: 'Task Created & Matched',
                      time: '',
                      isCompleted: true,
                    ),
                    _buildTimelineStep(
                      title: 'Helper Heading to Pickup',
                      time: '',
                      isCompleted: isAccepted,
                      isCurrent: isEnRoutePickup,
                    ),
                    _buildTimelineStep(
                      title: 'Pickup Confirmed & Route to Dropoff',
                      time: '',
                      isCompleted: isPickupConfirmed || isCompleted,
                      isCurrent: isPickupConfirmed && !isCompleted,
                    ),
                    _buildTimelineStep(
                      title: 'Completed & Delivered',
                      time: '',
                      isCompleted: isCompleted,
                      isCurrent: isCompleted,
                      isLast: true,
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Quick action to view helper proof submission demo
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CareDropTheme.tealPrimary,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PatientReviewProofScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    'Review Helper Proof',
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

  Widget _buildTimelineStep({
    required String title,
    required String time,
    required bool isCompleted,
    bool isCurrent = false,
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isCompleted
                    ? (isCurrent ? CareDropTheme.tealPrimary : const Color(0xFFDCFCE7))
                    : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: Icon(
                  isCompleted ? Icons.check : Icons.circle,
                  size: 14,
                  color: isCompleted
                      ? (isCurrent ? Colors.white : const Color(0xFF16A34A))
                      : Colors.transparent,
                ),
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 28,
                color: isCompleted ? CareDropTheme.tealPrimary.withValues(alpha: 0.3) : const Color(0xFFE2E8F0),
              ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal,
                    fontSize: 14,
                    color: isCompleted ? CareDropTheme.textPrimary : CareDropTheme.textMuted,
                  ),
                ),
                if (isCurrent)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Now',
                      style: TextStyle(
                        color: CareDropTheme.tealPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else if (time.isNotEmpty)
                  Text(
                    time,
                    style: const TextStyle(
                      fontSize: 12,
                      color: CareDropTheme.textMuted,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
