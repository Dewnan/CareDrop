import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/task_model.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import 'task_details_screen.dart';

class TaskBrowseScreen extends StatefulWidget {
  const TaskBrowseScreen({super.key});

  @override
  State<TaskBrowseScreen> createState() => _TaskBrowseScreenState();
}

class _TaskBrowseScreenState extends State<TaskBrowseScreen> {
  TaskCategory _selectedCategory = TaskCategory.all;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<CareDropAppState>();

    final filteredTasks = appState.availableTasks.where((task) {
      if (_selectedCategory == TaskCategory.all) return true;
      if (_selectedCategory == TaskCategory.urgent) return task.isUrgent;
      return task.category == _selectedCategory;
    }).toList();

    return Scaffold(
      backgroundColor: CareDropTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Available Tasks',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: CareDropTheme.cardBorderColor),
                backgroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              icon: const Icon(Icons.filter_list_rounded, size: 16, color: CareDropTheme.textPrimary),
              label: const Text(
                'Filter',
                style: TextStyle(color: CareDropTheme.textPrimary, fontSize: 12),
              ),
              onPressed: () {
                _showFilterBottomSheet(context);
              },
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips Horizontal Scroll
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _FilterChip(
                  label: 'All',
                  isSelected: _selectedCategory == TaskCategory.all,
                  onTap: () => setState(() => _selectedCategory = TaskCategory.all),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Urgent',
                  isSelected: _selectedCategory == TaskCategory.urgent,
                  onTap: () => setState(() => _selectedCategory = TaskCategory.urgent),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Medicine',
                  isSelected: _selectedCategory == TaskCategory.medicine,
                  onTap: () => setState(() => _selectedCategory = TaskCategory.medicine),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Document Filing',
                  isSelected: _selectedCategory == TaskCategory.filing,
                  onTap: () => setState(() => _selectedCategory = TaskCategory.filing),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Queue',
                  isSelected: _selectedCategory == TaskCategory.queue,
                  onTap: () => setState(() => _selectedCategory = TaskCategory.queue),
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: filteredTasks.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final task = filteredTasks[index];
                return _TaskBrowseTile(
                  task: task,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TaskDetailsScreen(task: task),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Filter Tasks',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Show All Tasks'),
                trailing: _selectedCategory == TaskCategory.all ? const Icon(Icons.check, color: CareDropTheme.tealPrimary) : null,
                onTap: () {
                  setState(() => _selectedCategory = TaskCategory.all);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('Urgent Only'),
                trailing: _selectedCategory == TaskCategory.urgent ? const Icon(Icons.check, color: CareDropTheme.tealPrimary) : null,
                onTap: () {
                  setState(() => _selectedCategory = TaskCategory.urgent);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('Medicine Pickups'),
                trailing: _selectedCategory == TaskCategory.medicine ? const Icon(Icons.check, color: CareDropTheme.tealPrimary) : null,
                onTap: () {
                  setState(() => _selectedCategory = TaskCategory.medicine);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? CareDropTheme.tealPrimary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? CareDropTheme.tealPrimary : CareDropTheme.cardBorderColor,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : CareDropTheme.textPrimary,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _TaskBrowseTile extends StatelessWidget {
  final TaskModel task;
  final VoidCallback onTap;

  const _TaskBrowseTile({
    required this.task,
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: CareDropTheme.cardBorderColor),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFE6F4F1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.widgets_outlined,
                color: CareDropTheme.tealPrimary,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: CareDropTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    task.hospital,
                    style: const TextStyle(
                      color: CareDropTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 14, color: CareDropTheme.textMuted),
                      const SizedBox(width: 2),
                      Text(
                        task.distanceStr,
                        style: const TextStyle(
                          color: CareDropTheme.textMuted,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: task.isUrgent ? CareDropTheme.urgentBg : CareDropTheme.normalBg,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          task.isUrgent ? 'Urgent' : 'Normal',
                          style: TextStyle(
                            color: task.isUrgent ? CareDropTheme.urgentText : CareDropTheme.normalText,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Text(
              '${task.currency} ${task.price.toInt()}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: CareDropTheme.tealPrimary,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
