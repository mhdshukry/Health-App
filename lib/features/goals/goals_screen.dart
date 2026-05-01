import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/app_scaffold.dart';
import '../../shared/form_options.dart';
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
    final formKey = GlobalKey<FormState>();
    final title = TextEditingController();
    var selectedType = goalTypeOptions.first;
    final target = TextEditingController(text: '10000');
    final current = TextEditingController(text: '0');
    DateTime targetDate = DateTime.now().add(const Duration(days: 30));

    await showAppModal<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (dialogContext, setModalState) => Padding(
          padding: const EdgeInsets.all(18),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.flag_outlined),
                      const SizedBox(width: 10),
                      Text('Add goal',
                          style: Theme.of(dialogContext).textTheme.titleLarge),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: title,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(labelText: 'Goal title'),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Required'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedType,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Goal type',
                    ),
                    items: goalTypeOptions
                        .map((value) => DropdownMenuItem(
                              value: value,
                              child: Text(optionLabel(value)),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) selectedType = value;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: target,
                    decoration:
                        const InputDecoration(labelText: 'Target value'),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) =>
                        double.tryParse(value?.trim() ?? '') == null
                            ? 'Enter target'
                            : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: current,
                    decoration:
                        const InputDecoration(labelText: 'Current value'),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) =>
                        double.tryParse(value?.trim() ?? '') == null
                            ? 'Enter current value'
                            : null,
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: dialogContext,
                        initialDate: targetDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 730)),
                      );
                      if (picked != null) {
                        setModalState(() => targetDate = picked);
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Target date',
                        suffixIcon: Icon(Icons.calendar_today_outlined),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          formatDate(targetDate.toIso8601String()),
                          style: Theme.of(dialogContext)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            if (!formKey.currentState!.validate()) return;
                            final error = await ref
                                .read(wellnessControllerProvider.notifier)
                                .addGoal(
                                  title: title.text.trim(),
                                  goalType: selectedType,
                                  targetValue: double.parse(target.text.trim()),
                                  currentValue:
                                      double.parse(current.text.trim()),
                                  targetDate: targetDate,
                                );
                            if (!dialogContext.mounted) return;
                            if (error != null) {
                              ScaffoldMessenger.of(dialogContext).showSnackBar(
                                SnackBar(content: Text(error)),
                              );
                              return;
                            }
                            Navigator.pop(dialogContext);
                          },
                          child: const Text('Save'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    title.dispose();
    target.dispose();
    current.dispose();
  }

  Future<void> _showProgressDialog(BuildContext context, WidgetRef ref,
      String goalId, double initial) async {
    final current = TextEditingController(text: initial.toStringAsFixed(1));
    await showAppModal<void>(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(18),
        child: Wrap(
          runSpacing: 12,
          children: [
            Text('Update progress',
                style: Theme.of(context).textTheme.titleLarge),
            TextField(
              controller: current,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Current value'),
            ),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
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
                          const SnackBar(
                              content: Text('Please enter a valid number.')),
                        );
                      }
                    },
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
