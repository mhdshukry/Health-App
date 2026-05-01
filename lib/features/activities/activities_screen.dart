import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/app_scaffold.dart';
import '../../shared/form_options.dart';
import '../../shared/widgets.dart';
import '../../state/wellness_controller.dart';

class ActivitiesScreen extends ConsumerWidget {
  const ActivitiesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(wellnessControllerProvider).requireValue;
    final controller = ref.read(wellnessControllerProvider.notifier);
    final items = controller.userActivities(state);

    return AppScaffold(
      title: 'Activities',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddActivity(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Activity'),
      ),
      child: items.isEmpty
          ? const EmptyState(
              title: 'No activities found',
              message: 'Add your first activity to start tracking progress.',
            )
          : ListView.separated(
              padding: const EdgeInsets.only(bottom: 96),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, index) {
                final activity = items[index];
                return SectionCard(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      activity.type[0].toUpperCase() +
                          activity.type.substring(1),
                    ),
                    subtitle: Text(
                      '${formatDateTime(activity.date)}\n${activity.duration} min - ${activity.steps} steps - ${activity.calories} kcal',
                    ),
                    trailing: IconButton(
                      onPressed: () => controller.deleteActivity(activity.id),
                      icon: const Icon(Icons.delete_outline),
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            ),
    );
  }

  Future<void> _showAddActivity(BuildContext context, WidgetRef ref) async {
    final formKey = GlobalKey<FormState>();
    var selectedType = activityTypeOptions.first;
    final duration = TextEditingController(text: '30');
    final steps = TextEditingController(text: '5000');
    final distance = TextEditingController(text: '3.5');
    final calories = TextEditingController(text: '220');
    final notes = TextEditingController();

    await showAppModal<void>(
      context: context,
      builder: (sheetContext) => Padding(
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
                    const Icon(Icons.directions_walk_outlined),
                    const SizedBox(width: 10),
                    Text(
                      'Add activity',
                      style: Theme.of(sheetContext).textTheme.titleLarge,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Activity type'),
                  items: activityTypeOptions
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text(optionLabel(value)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) selectedType = value;
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _numberField(
                        duration,
                        'Duration',
                        suffix: 'min',
                        integer: true,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _numberField(
                        steps,
                        'Steps',
                        integer: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _numberField(distance, 'Distance', suffix: 'km'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _numberField(
                        calories,
                        'Calories',
                        suffix: 'kcal',
                        integer: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: notes,
                  minLines: 2,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Notes'),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(sheetContext),
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
                              .addActivity(
                                type: selectedType,
                                duration: int.parse(duration.text.trim()),
                                steps: int.parse(steps.text.trim()),
                                distance: double.parse(distance.text.trim()),
                                calories: int.parse(calories.text.trim()),
                                notes: notes.text.trim(),
                                date: DateTime.now(),
                              );
                          if (!sheetContext.mounted) return;
                          if (error != null) {
                            ScaffoldMessenger.of(sheetContext).showSnackBar(
                              SnackBar(content: Text(error)),
                            );
                            return;
                          }
                          Navigator.pop(sheetContext);
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
    );

    duration.dispose();
    steps.dispose();
    distance.dispose();
    calories.dispose();
    notes.dispose();
  }

  TextFormField _numberField(
    TextEditingController controller,
    String label, {
    String? suffix,
    bool integer = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(decimal: !integer),
      decoration: InputDecoration(labelText: label, suffixText: suffix),
      validator: (value) {
        final raw = value?.trim() ?? '';
        final valid =
            integer ? int.tryParse(raw) != null : double.tryParse(raw) != null;
        if (!valid) return 'Required';
        return null;
      },
    );
  }
}
