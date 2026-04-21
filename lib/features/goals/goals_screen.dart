import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/app_scaffold.dart';
import '../../shared/widgets.dart';
import '../../state/wellness_controller.dart';

class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(wellnessControllerProvider).requireValue;
    final controller = ref.read(wellnessControllerProvider.notifier);
    final items = controller.userGoals(state);

    return AppScaffold(
      title: 'Goals',
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddGoal(context, ref),
        child: const Icon(Icons.add),
      ),
      child: items.isEmpty
          ? const EmptyState(
              title: 'No goals yet',
              message: 'Set a measurable goal and track your daily progress.')
          : ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, index) {
                final goal = items[index];
                return SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                              child: Text(goal.title,
                                  style:
                                      Theme.of(context).textTheme.titleMedium)),
                          Chip(
                            backgroundColor: goal.status == 'completed'
                                ? Colors.green.withOpacity(0.18)
                                : Colors.orange.withOpacity(0.18),
                            label: Text(goal.status,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                          '${goal.currentValue.toStringAsFixed(1)} / ${goal.targetValue.toStringAsFixed(1)} ${goal.goalType}'),
                      const SizedBox(height: 12),
                      LinearProgressIndicator(value: goal.progress),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                              child: Text(
                                  'Target: ${formatDate(goal.targetDate)}',
                                  style:
                                      Theme.of(context).textTheme.bodyMedium)),
                          TextButton(
                            onPressed: () => _showProgressDialog(
                                context, ref, goal.id, goal.currentValue),
                            child: const Text('Update'),
                          ),
                        ],
                      )
                    ],
                  ),
                );
              },
            ),
    );
  }

  Future<void> _showAddGoal(BuildContext context, WidgetRef ref) async {
    final title = TextEditingController();
    final type = TextEditingController(text: 'steps');
    final target = TextEditingController(text: '10000');
    final current = TextEditingController(text: '0');
    DateTime targetDate = DateTime.now().add(const Duration(days: 30));

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
              16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
          child: Wrap(
            runSpacing: 12,
            children: [
              Text('Add goal', style: Theme.of(context).textTheme.titleLarge),
              TextField(
                  controller: title,
                  decoration: const InputDecoration(labelText: 'Goal title')),
              TextField(
                  controller: type,
                  decoration: const InputDecoration(
                      labelText: 'Goal type (steps, kg, workouts, etc.)')),
              TextField(
                  controller: target,
                  decoration: const InputDecoration(labelText: 'Target value'),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true)),
              TextField(
                  controller: current,
                  decoration: const InputDecoration(labelText: 'Current value'),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true)),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                    'Target date: ${formatDate(targetDate.toIso8601String())}'),
                trailing: const Icon(Icons.calendar_today_outlined),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: targetDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 730)),
                  );
                  if (picked != null) setModalState(() => targetDate = picked);
                },
              ),
              ElevatedButton(
                onPressed: () async {
                  try {
                    await ref.read(wellnessControllerProvider.notifier).addGoal(
                          title: title.text.trim(),
                          goalType: type.text.trim(),
                          targetValue: double.parse(target.text.trim()),
                          currentValue: double.parse(current.text.trim()),
                          targetDate: targetDate,
                        );
                    if (context.mounted) Navigator.pop(context);
                  } catch (_) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Please enter valid numbers.')),
                    );
                  }
                },
                child: const Text('Save goal'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showProgressDialog(BuildContext context, WidgetRef ref,
      String goalId, double initial) async {
    final current = TextEditingController(text: initial.toStringAsFixed(1));
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update progress'),
        content: TextField(
          controller: current,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Current value'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              try {
                await ref
                    .read(wellnessControllerProvider.notifier)
                    .updateGoalProgress(
                        goalId, double.parse(current.text.trim()));
                if (context.mounted) Navigator.pop(context);
              } catch (_) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid number.')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
