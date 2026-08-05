import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'patient_task_specifications_screen.dart';

class PatientTaskTypeScreen extends StatelessWidget {
  const PatientTaskTypeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final taskTypes = [
      {
        'title': 'Medication Pickup',
        'subtitle': 'Collect prescription from pharmacy',
        'icon': Icons.inventory_2_outlined,
        'bgColor': const Color(0xFFEFF6FF),
        'iconColor': CareDropTheme.tealPrimary,
      },
      {
        'title': 'Hospital Delivery',
        'subtitle': 'Deliver items to patient at ward',
        'icon': Icons.local_shipping_outlined,
        'bgColor': const Color(0xFFECFDF5),
        'iconColor': const Color(0xFF10B981),
      },
      {
        'title': 'Patient Escort',
        'subtitle': 'Accompany patient to appointments',
        'icon': Icons.access_time,
        'bgColor': const Color(0xFFF5F3FF),
        'iconColor': const Color(0xFF8B5CF6),
      },
      {
        'title': 'Document Filing',
        'subtitle': 'Submit or collect medical documents',
        'icon': Icons.description_outlined,
        'bgColor': const Color(0xFFFEF3C7),
        'iconColor': const Color(0xFFF59E0B),
      },
      {
        'title': 'General Errand',
        'subtitle': 'Any other care-related task',
        'icon': Icons.error_outline,
        'bgColor': const Color(0xFFFEE2E2),
        'iconColor': const Color(0xFFEF4444),
      },
      {
        'title': 'Queue Management',
        'subtitle': 'Hold queue on behalf of patient',
        'icon': Icons.check_circle_outline,
        'bgColor': const Color(0xFFDCFCE7),
        'iconColor': const Color(0xFF16A34A),
      },
    ];

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
          'Task Type',
          style: TextStyle(
            color: CareDropTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Text(
              'What kind of help do you need?',
              style: TextStyle(
                fontSize: 14,
                color: CareDropTheme.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: taskTypes.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final type = taskTypes[index];
                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PatientTaskSpecificationsScreen(
                          taskTypeName: type['title'] as String,
                        ),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: CareDropTheme.cardBorderColor),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: type['bgColor'] as Color,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            type['icon'] as IconData,
                            color: type['iconColor'] as Color,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                type['title'] as String,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: CareDropTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                type['subtitle'] as String,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: CareDropTheme.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right,
                          color: CareDropTheme.textMuted,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
