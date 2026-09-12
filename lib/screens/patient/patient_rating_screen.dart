import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../components/feedback_banner.dart';
import '../../providers/app_state.dart';
import '../../services/review_service.dart';
import '../../theme/app_theme.dart';
import 'patient_dashboard_screen.dart';

/// Screen allowing patients to rate their matched helper after task completion (optional).
class PatientRatingScreen extends StatefulWidget {
  final String? taskId;
  final String? helperName;
  final String? helperId;

  const PatientRatingScreen({
    super.key,
    this.taskId,
    this.helperName,
    this.helperId,
  });

  @override
  State<PatientRatingScreen> createState() => _PatientRatingScreenState();
}

class _PatientRatingScreenState extends State<PatientRatingScreen> {
  int _selectedRating = 5;
  final Set<String> _selectedTags = {'Punctual', 'Friendly', 'Careful'};
  final TextEditingController _commentController = TextEditingController();

  final List<String> _tags = [
    'Punctual',
    'Friendly',
    'Careful',
    'Professional',
    'Communicative',
  ];

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  /// Submits review to Firestore or skips rating and navigates back to patient home.
  Future<void> _finishRating({bool isSkipped = false}) async {
    if (!isSkipped && widget.helperId != null && widget.helperId!.isNotEmpty) {
      final user = context.read<CareDropAppState>().currentUserModel;
      final reviewerId = user?.id ?? '';
      final reviewerName = user?.fullName ?? 'Patient User';

      await ReviewService.createReview(
        taskId: widget.taskId ?? '',
        reviewerId: reviewerId,
        reviewerName: reviewerName,
        helperId: widget.helperId!,
        rating: _selectedRating.toDouble(),
        tags: _selectedTags.toList(),
        comment: _commentController.text.trim(),
      );

      if (mounted) {
        FeedbackBanner.show(
          context,
          message: 'Thank you for rating your helper!',
          type: FeedbackType.success,
        );
      }
    }

    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const PatientDashboardScreen(),
        ),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayName = widget.helperName ?? 'your Helper';

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
          'Rate Your Helper',
          style: TextStyle(
            color: CareDropTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => _finishRating(isSkipped: true),
            child: const Text(
              'Skip',
              style: TextStyle(color: CareDropTheme.textMuted, fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 10),

              // Green check circle
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Icon(Icons.check_circle_outline, color: Color(0xFF16A34A), size: 40),
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                'Task Completed!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: CareDropTheme.textPrimary,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                'How was $displayName?',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  color: CareDropTheme.textSecondary,
                ),
              ),

              const SizedBox(height: 24),

              // Star Rating Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final starIndex = index + 1;
                  return IconButton(
                    iconSize: 36,
                    icon: Icon(
                      starIndex <= _selectedRating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                    ),
                    onPressed: () {
                      setState(() {
                        _selectedRating = starIndex;
                      });
                    },
                  );
                }),
              ),

              const SizedBox(height: 24),

              // Tag Chips Wrap
              Wrap(
                spacing: 8,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: _tags.map((tag) {
                  final isSelected = _selectedTags.contains(tag);
                  return ChoiceChip(
                    label: Text(tag),
                    selected: isSelected,
                    selectedColor: CareDropTheme.royalBlue,
                    backgroundColor: Colors.white,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : CareDropTheme.textPrimary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: isSelected ? CareDropTheme.royalBlue : CareDropTheme.cardBorderColor,
                      ),
                    ),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedTags.add(tag);
                        } else {
                          _selectedTags.remove(tag);
                        }
                      });
                    },
                  );
                }).toList(),
              ),

              const Spacer(),

              // Submit Review Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CareDropTheme.royalBlue,
                  ),
                  onPressed: () => _finishRating(isSkipped: false),
                  child: const Text(
                    'Submit Review',
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
}
