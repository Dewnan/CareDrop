import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../components/review_card_tile.dart';
import '../../models/review_model.dart';
import '../../models/user_model.dart';
import '../../services/review_service.dart';
import '../../theme/app_theme.dart';
import 'patient_live_helper_map_screen.dart';
import 'patient_rating_screen.dart';

/// Screen displaying matched helper details along with embedded dynamic real-time task status timeline.
class PatientMatchedHelperScreen extends StatefulWidget {
  final String taskId;
  final UserModel? helperModel;

  const PatientMatchedHelperScreen({
    super.key,
    required this.taskId,
    this.helperModel,
  });

  @override
  State<PatientMatchedHelperScreen> createState() => _PatientMatchedHelperScreenState();
}

class _PatientMatchedHelperScreenState extends State<PatientMatchedHelperScreen> {
  UserModel? _helperModel;
  int _completedTaskCount = 0;

  @override
  void initState() {
    super.initState();
    _helperModel = widget.helperModel;
    if (_helperModel == null && widget.taskId.isNotEmpty) {
      _fetchHelperDetailsFromTask();
    } else if (_helperModel != null) {
      _fetchCompletedTaskCount(_helperModel!.id);
    }
  }

  /// Fetches assigned helper details from Firestore if helper model was not provided.
  Future<void> _fetchHelperDetailsFromTask() async {
    try {
      final taskDoc = await FirebaseFirestore.instance.collection('tasks').doc(widget.taskId).get();
      final assignedHelperId = taskDoc.data()?['assignedHelperId'] as String?;
      if (assignedHelperId != null && assignedHelperId.isNotEmpty) {
        final helperDoc = await FirebaseFirestore.instance.collection('users').doc(assignedHelperId).get();
        if (helperDoc.exists && helperDoc.data() != null) {
          if (mounted) {
            setState(() {
              _helperModel = UserModel.fromMap(helperDoc.data()!, docId: helperDoc.id);
            });
            _fetchCompletedTaskCount(assignedHelperId);
          }
        }
      }
    } catch (_) {
      // Handles fetch failure gracefully
    }
  }

  /// Queries Firestore for the helper's completed task count.
  Future<void> _fetchCompletedTaskCount(String helperId) async {
    if (helperId.isEmpty) return;
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('tasks')
          .where('assignedHelperId', isEqualTo: helperId)
          .where('progressStep', isEqualTo: 'completed')
          .get();

      if (mounted) {
        setState(() {
          _completedTaskCount = snapshot.docs.length;
        });
      }
    } catch (_) {}
  }

  /// Displays modal bottom sheet with comprehensive helper info, contact methods, stats, and real patient reviews from Firestore.
  void _showHelperDetailsBottomSheet(BuildContext context) {
    final helperName = _helperModel?.fullName ?? 'Assigned Helper';
    final initials = helperName.split(' ').take(2).map((e) => e.isNotEmpty ? e[0] : '').join();
    final helperId = _helperModel?.id ?? '';
    final ratingStr = (_helperModel?.rating ?? 5.0).toStringAsFixed(1);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomCtx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: CareDropTheme.cardBorderColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Helper Header Info
                Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: CareDropTheme.royalBlue,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text(
                          initials.isEmpty ? 'H' : initials,
                          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            helperName,
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: CareDropTheme.textPrimary),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.star, color: Colors.amber, size: 18),
                              const SizedBox(width: 4),
                              Text('$ratingStr ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              Text('· $_completedTaskCount Tasks Completed', style: const TextStyle(color: CareDropTheme.textMuted, fontSize: 13)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Verified Helper',
                              style: TextStyle(color: Color(0xFF16A34A), fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 20),

                // Past Patient Reviews Section Streamed from Firestore
                const Text(
                  'PAST REVIEWS & FEEDBACK',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: CareDropTheme.textMuted,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),

                StreamBuilder<List<ReviewModel>>(
                  stream: ReviewService.streamHelperReviews(helperId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      );
                    }

                    final reviews = snapshot.data ?? [];

                    if (reviews.isEmpty) {
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: CareDropTheme.cardBorderColor),
                        ),
                        child: const Column(
                          children: [
                            Icon(Icons.rate_review_outlined, size: 32, color: CareDropTheme.textMuted),
                            SizedBox(height: 6),
                            Text(
                              'No past reviews yet',
                              style: TextStyle(fontWeight: FontWeight.bold, color: CareDropTheme.textPrimary, fontSize: 13),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Be the first to review after task completion.',
                              style: TextStyle(color: CareDropTheme.textMuted, fontSize: 12),
                            ),
                          ],
                        ),
                      );
                    }

                    return Column(
                      children: reviews.map((r) => ReviewCardTile(review: r)).toList(),
                    );
                  },
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Returns category-specific human-readable status badge label.
  String _getStatusBadgeLabel(String categoryStr, String progressStep) {
    final isCaregiver = categoryStr == 'queue' || categoryStr == 'all';

    switch (progressStep) {
      case 'pending':
        return 'Searching Helper';
      case 'taskAccepted':
        return isCaregiver ? 'Helper Matched & Heading' : 'Helper Heading to Pickup';
      case 'enRoute':
        return isCaregiver ? 'En Route to Patient' : 'En Route to Pickup';
      case 'arrivedAtLocation':
        return isCaregiver ? 'Arrived at Location' : 'Arrived at Pickup';
      case 'inProgress':
        return isCaregiver ? 'Assisting Patient' : 'Package Picked Up & On Route';
      case 'uploadProof':
        return 'Proof Submitted for Review';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'In Progress';
    }
  }

  @override
  Widget build(BuildContext context) {
    final helperName = _helperModel?.fullName ?? 'Assigned Helper';
    final initials = helperName.split(' ').take(2).map((e) => e.isNotEmpty ? e[0] : '').join();

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
          'Matched Helper & Status',
          style: TextStyle(
            color: CareDropTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('tasks').doc(widget.taskId).snapshots(),
          builder: (context, snapshot) {
            final taskData = snapshot.data?.data();
            final progressStep = taskData?['progressStep'] as String? ?? 'taskAccepted';
            final taskTitle = taskData?['title'] as String? ?? 'Care Service Task';
            final hospital = taskData?['hospital'] as String? ?? 'Local Hospital / Clinic';
            final categoryStr = taskData?['category'] as String? ?? 'all';
            final isCaregiver = categoryStr == 'queue' || categoryStr == 'all';
            final isCompleted = progressStep == 'completed';

            final isAccepted = progressStep != 'pending';
            caseStepActive(String step) {
              if (progressStep == 'completed') return true;
              if (step == 'accepted') return isAccepted;
              if (step == 'enroute') return progressStep == 'enRoute' || progressStep == 'arrivedAtLocation' || progressStep == 'inProgress' || progressStep == 'uploadProof' || isCompleted;
              if (step == 'inProgress') return progressStep == 'inProgress' || progressStep == 'uploadProof' || isCompleted;
              if (step == 'completed') return isCompleted;
              return false;
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section 1: Helper Info Card (Clickable to open helper details)
                  InkWell(
                    onTap: () => _showHelperDetailsBottomSheet(context),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
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
                              // Avatar Box
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: CareDropTheme.royalBlue,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Text(
                                    initials.isEmpty ? 'H' : initials,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      helperName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: CareDropTheme.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.star, color: Colors.amber, size: 16),
                                        const SizedBox(width: 4),
                                        const Text(
                                          '5.0 ',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(
                                            '· ${_helperModel?.phone.isNotEmpty == true ? _helperModel!.phone : 'Verified Helper'}',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: CareDropTheme.textMuted,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFDCFCE7),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'Verified Helper',
                                        style: TextStyle(
                                          color: Color(0xFF16A34A),
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios, size: 16, color: CareDropTheme.textMuted),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: const [
                              Icon(Icons.location_on_outlined, size: 16, color: CareDropTheme.textMuted),
                              SizedBox(width: 4),
                              Text(
                                'Nearby · Tap for helper details & reviews',
                                style: TextStyle(color: CareDropTheme.textSecondary, fontSize: 13),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Section 2: Task Status Card Placed Under Helper Info Card
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
                              child: Icon(
                                isCaregiver ? Icons.accessibility_new_rounded : Icons.inventory_2_outlined,
                                color: CareDropTheme.royalBlue,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    taskTitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: CareDropTheme.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    hospital,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: CareDropTheme.textMuted, fontSize: 12),
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: isCompleted
                                          ? const Color(0xFFDCFCE7)
                                          : const Color(0xFFFEF3C7),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      _getStatusBadgeLabel(categoryStr, progressStep),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
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

                        // Section Title
                        const Text(
                          'LIVE TASK PROGRESS',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: CareDropTheme.textMuted,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Dynamic Category-Aware Timeline Steps
                        _buildTimelineStep(
                          title: 'Task Created & Matched',
                          isCompleted: true,
                          isCurrent: false,
                        ),
                        _buildTimelineStep(
                          title: isCaregiver ? 'Helper En Route to Patient' : 'Helper Heading to Pickup',
                          isCompleted: caseStepActive('accepted'),
                          isCurrent: progressStep == 'taskAccepted' || progressStep == 'enRoute',
                        ),
                        _buildTimelineStep(
                          title: isCaregiver ? 'Assisting Patient at Hospital' : 'Pickup Confirmed & On Route',
                          isCompleted: caseStepActive('inProgress'),
                          isCurrent: progressStep == 'arrivedAtLocation' || progressStep == 'inProgress' || progressStep == 'uploadProof',
                        ),
                        _buildTimelineStep(
                          title: isCaregiver ? 'Caregiver Service Completed' : 'Completed & Delivered',
                          isCompleted: isCompleted,
                          isCurrent: isCompleted,
                          isLast: true,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Section 3: Action Buttons (Call Helper & Open Map)
                  if (progressStep == 'completed' || progressStep == 'uploadProof')
                    Row(
                      children: [
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            side: const BorderSide(color: CareDropTheme.royalBlue),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () async {
                            final phone = _helperModel?.phone ?? '';
                            if (phone.isNotEmpty && phone != 'Contact Unavailable') {
                              final uri = Uri.parse('tel:$phone');
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri);
                              }
                            }
                          },
                          child: const Icon(Icons.phone, color: CareDropTheme.royalBlue, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: 50,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF10B981),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => PatientRatingScreen(
                                      taskId: widget.taskId,
                                      helperName: helperName,
                                      helperId: _helperModel?.id,
                                    ),
                                  ),
                                );
                              },
                              child: const Text(
                                'Complete & Rate Helper',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 50,
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: CareDropTheme.royalBlue),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              icon: const Icon(Icons.phone, color: CareDropTheme.royalBlue, size: 18),
                              onPressed: () async {
                                final phone = _helperModel?.phone ?? '';
                                if (phone.isNotEmpty && phone != 'Contact Unavailable') {
                                  final uri = Uri.parse('tel:$phone');
                                  if (await canLaunchUrl(uri)) {
                                    await launchUrl(uri);
                                  }
                                }
                              },
                              label: const Text(
                                'Call Helper',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: CareDropTheme.royalBlue, fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: 50,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: CareDropTheme.royalBlue,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => PatientLiveHelperMapScreen(taskId: widget.taskId),
                                  ),
                                );
                              },
                              child: const Text(
                                'Open Map',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// Builds a single timeline step tile with text overflow protection.
  Widget _buildTimelineStep({
    required String title,
    required bool isCompleted,
    required bool isCurrent,
    bool isLast = false,
  }) {
    final dotColor = isCompleted
        ? CareDropTheme.royalBlue
        : isCurrent
            ? const Color(0xFF3B82F6)
            : CareDropTheme.cardBorderColor;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: isCompleted ? CareDropTheme.royalBlue : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: dotColor, width: 2),
              ),
              child: isCompleted
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                  : (isCurrent
                      ? Center(
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFF3B82F6),
                              shape: BoxShape.circle,
                            ),
                          ),
                        )
                      : null),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 36,
                color: isCompleted ? CareDropTheme.royalBlue : CareDropTheme.cardBorderColor,
              ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: isCompleted || isCurrent ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
                color: isCompleted || isCurrent ? CareDropTheme.textPrimary : CareDropTheme.textMuted,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
