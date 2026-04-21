import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/app_scaffold.dart';
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddActivity(context, ref),
        child: const Icon(Icons.add),
      ),
      child: items.isEmpty
          ? const EmptyState(
              title: 'No activities found',
              message: 'Add your first activity to start tracking progress.')
          : ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, index) {
                final activity = items[index];
                return SectionCard(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(activity.type[0].toUpperCase() +
                        activity.type.substring(1)),
                    subtitle: Text(
                        '${formatDateTime(activity.date)}\n${activity.duration} min · ${activity.steps} steps · ${activity.calories} kcal'),
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
    final type = TextEditingController(text: 'walking');
    final duration = TextEditingController(text: '30');
    final steps = TextEditingController(text: '5000');
    final distance = TextEditingController(text: '3.5');
    final calories = TextEditingController(text: '220');
    final notes = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
            16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
        child: Form(
          key: formKey,
          child: Wrap(
            runSpacing: 12,
            children: [
              Text('Add activity',
                  style: Theme.of(context).textTheme.titleLarge),
              TextFormField(
                  controller: type,
                  decoration: const InputDecoration(
                      labelText:
                          'Type (walking, running, cycling, workout, yoga, stretching)')),
              TextFormField(
                  controller: duration,
                  decoration:
                      const InputDecoration(labelText: 'Duration (minutes)'),
                  keyboardType: TextInputType.number),
              TextFormField(
                  controller: steps,
                  decoration: const InputDecoration(labelText: 'Steps'),
                  keyboardType: TextInputType.number),
              TextFormField(
                  controller: distance,
                  decoration: const InputDecoration(labelText: 'Distance (km)'),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true)),
              TextFormField(
                  controller: calories,
                  decoration: const InputDecoration(labelText: 'Calories'),
                  keyboardType: TextInputType.number),
              TextFormField(
                  controller: notes,
                  decoration: const InputDecoration(labelText: 'Notes')),
              ElevatedButton(
                onPressed: () async {
                  await ref
                      .read(wellnessControllerProvider.notifier)
                      .addActivity(
                        type: type.text.trim().toLowerCase(),
                        duration: int.parse(duration.text.trim()),
                        steps: int.parse(steps.text.trim()),
                        distance: double.parse(distance.text.trim()),
                        calories: int.parse(calories.text.trim()),
                        notes: notes.text.trim(),
                        date: DateTime.now(),
                      );
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text('Save activity'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
