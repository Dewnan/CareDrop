import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'patient_create_task_form_screen.dart';

class PatientTaskTypeScreen extends StatelessWidget {
  const PatientTaskTypeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final taskTypes = [
      {
        'title': 'Medicine Pickup',
        'subtitle': 'Collect prescription & medicine from pharmacy',
        'icon': Icons.inventory_2_outlined,
        'bgColor': const Color(0xFFEFF6FF),
        'iconColor': CareDropTheme.royalBlue,
      },
      {
        'title': 'Food Pickup',
        'subtitle': 'Deliver food/meals to patient at hospital ward',
        'icon': Icons.fastfood_outlined,
        'bgColor': const Color(0xFFECFDF5),
        'iconColor': const Color(0xFF10B981),
      },
      {
        'title': 'Document Delivery',
        'subtitle': 'Submit or collect medical documents & reports',
        'icon': Icons.description_outlined,
        'bgColor': const Color(0xFFFEF3C7),
        'iconColor': const Color(0xFFF59E0B),
      },
      {
        'title': 'Queue/Token Assistance',
        'subtitle': 'Hold queue/token on behalf of patient',
        'icon': Icons.confirmation_number_outlined,
        'bgColor': const Color(0xFFDCFCE7),
        'iconColor': const Color(0xFF16A34A),
      },
      {
        'title': 'Pharmacy Purchase',
        'subtitle': 'Purchase non-prescription medical supplies',
        'icon': Icons.local_pharmacy_outlined,
        'bgColor': const Color(0xFFF5F3FF),
        'iconColor': const Color(0xFF8B5CF6),
      },
      {
        'title': 'Other',
        'subtitle': 'Any other care-related hospital task',
        'icon': Icons.more_horiz,
        'bgColor': const Color(0xFFFEE2E2),
        'iconColor': const Color(0xFFEF4444),
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
                        builder: (_) => PatientCreateTaskFormScreen(
                          initialTaskType: type['title'] as String,
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
