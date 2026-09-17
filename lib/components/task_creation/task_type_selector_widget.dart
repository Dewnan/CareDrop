import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class TaskTypeSelectorWidget extends StatelessWidget {
  final List<String> taskTypeOptions;
  final String currentTaskType;
  final ValueChanged<String> onTaskTypeChanged;

  const TaskTypeSelectorWidget({
    super.key,
    required this.taskTypeOptions,
    required this.currentTaskType,
    required this.onTaskTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'SELECT TASK TYPE',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: CareDropTheme.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 48,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: taskTypeOptions.length,
            itemBuilder: (context, index) {
              final optionName = taskTypeOptions[index];
              final isSelected = currentTaskType == optionName;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  showCheckmark: false,
                  label: Text(
                    optionName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Colors.white : CareDropTheme.textPrimary,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: CareDropTheme.royalBlue,
                  backgroundColor: Colors.white,
                  onSelected: (val) {
                    if (val) {
                      onTaskTypeChanged(optionName);
                    }
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
