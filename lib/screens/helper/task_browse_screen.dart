import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../components/offline_task_placeholder.dart';
import '../../components/task_card_tile.dart';
import '../../models/task_model.dart';
import '../../providers/app_state.dart';
import '../../services/task_service.dart';
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
            child: () {
              final appState = context.watch<CareDropAppState>();
              final user = appState.helperUser;

              if (!user.isOnline) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: OfflineTaskPlaceholder(showBorder: false),
                  ),
                );
              }

              return StreamBuilder<List<TaskModel>>(
                stream: TaskService.streamPendingTasks(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final tasks = snapshot.data ?? [];
                  final filteredTasks = tasks.where((task) {
                    if (_selectedCategory == TaskCategory.all) return true;
                    if (_selectedCategory == TaskCategory.urgent) return task.isUrgent;
                    return task.category == _selectedCategory;
                  }).toList();

                  if (filteredTasks.isEmpty) {
                    return const Center(
                      child: Text(
                        'No pending tasks available right now.',
                        style: TextStyle(color: CareDropTheme.textMuted),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredTasks.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final task = filteredTasks[index];
                      return TaskCardTile(
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
                  );
                },
              );
            }(),
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
                trailing: _selectedCategory == TaskCategory.all ? const Icon(Icons.check, color: CareDropTheme.royalBlue) : null,
                onTap: () {
                  setState(() => _selectedCategory = TaskCategory.all);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('Urgent Only'),
                trailing: _selectedCategory == TaskCategory.urgent ? const Icon(Icons.check, color: CareDropTheme.royalBlue) : null,
                onTap: () {
                  setState(() => _selectedCategory = TaskCategory.urgent);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('Medicine Pickups'),
                trailing: _selectedCategory == TaskCategory.medicine ? const Icon(Icons.check, color: CareDropTheme.royalBlue) : null,
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
          color: isSelected ? CareDropTheme.royalBlue : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? CareDropTheme.royalBlue : CareDropTheme.cardBorderColor,
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


