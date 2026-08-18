import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../models/task_model.dart';
import '../../models/user_model.dart';
import '../../theme/app_theme.dart';
import 'patient_matched_helper_screen.dart';

class PatientSearchingHelpersScreen extends StatefulWidget {
  final String taskId;

  const PatientSearchingHelpersScreen({
    super.key,
    required this.taskId,
  });

  @override
  State<PatientSearchingHelpersScreen> createState() => _PatientSearchingHelpersScreenState();
}

class _PatientSearchingHelpersScreenState extends State<PatientSearchingHelpersScreen> {
  bool _isNavigating = false;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('tasks').doc(widget.taskId).snapshots(),
      builder: (context, snapshot) {
        final taskData = snapshot.data?.data();
        final progressStep = taskData?['progressStep'] as String? ?? 'pending';
        final assignedHelperId = taskData?['assignedHelperId'] as String?;

        // If a helper accepts, load helper profile and redirect once
        if (!_isNavigating && progressStep != 'pending' && assignedHelperId != null && assignedHelperId.isNotEmpty) {
          _isNavigating = true;
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            final helperDoc = await FirebaseFirestore.instance.collection('users').doc(assignedHelperId).get();
            final helperModel = helperDoc.exists && helperDoc.data() != null
                ? UserModel.fromMap(helperDoc.data()!, docId: helperDoc.id)
                : null;

            if (context.mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => PatientMatchedHelperScreen(
                    taskId: widget.taskId,
                    helperModel: helperModel,
                  ),
                ),
              );
            }
          });
        }

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: CareDropTheme.textPrimary),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'Finding Helper',
              style: TextStyle(color: CareDropTheme.textPrimary, fontWeight: FontWeight.bold),
            ),
            centerTitle: true,
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Spacer(),

                  // Clean circular indicator
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: CareDropTheme.royalBlue,
                        strokeWidth: 3,
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  const Text(
                    'Searching for Nearby Helpers...',
                    style: TextStyle(
                      color: CareDropTheme.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  const Text(
                    'Your request has been broadcasted to nearby verified helpers. Once a helper accepts, you will automatically connect here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: CareDropTheme.textSecondary,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),

                  const Spacer(),

                  // Cancel Task Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: CareDropTheme.cardBorderColor),
                        foregroundColor: const Color(0xFFEF4444),
                      ),
                      onPressed: () async {
                        await FirebaseFirestore.instance.collection('tasks').doc(widget.taskId).update({
                          'progressStep': TaskProgressStep.cancelled.name,
                        });
                        if (context.mounted) Navigator.pop(context);
                      },
                      child: const Text('Cancel Request', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
