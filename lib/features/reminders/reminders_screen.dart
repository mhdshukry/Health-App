import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/app_scaffold.dart';
import '../../shared/widgets.dart';
import '../../state/wellness_controller.dart';

class RemindersScreen extends ConsumerWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(wellnessControllerProvider).requireValue;
    final controller = ref.read(wellnessControllerProvider.notifier);
    final items = controller.userReminders(state);

    return AppScaffold(
      title: 'Reminders',
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddReminder(context, ref),
        child: const Icon(Icons.add_alert_outlined),
      ),
      child: items.isEmpty
          ? const EmptyState(
              title: 'No reminders yet',
              message:
                  'Add healthy routine reminders like workouts, hydration, or weight checks.')
          : ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, index) {
                final reminder = items[index];
                return SectionCard(
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(reminder.title),
                    subtitle: Text(
                        '${reminder.message}\n${reminder.scheduledTime} · ${reminder.repeat}'),
                    value: reminder.isActive,
                    onChanged: (_) => controller.toggleReminder(reminder.id),
                  ),
                );
              },
            ),
    );
  }

  Future<void> _showAddReminder(BuildContext context, WidgetRef ref) async {
    final title = TextEditingController();
    final message = TextEditingController();
    final time = TextEditingController(text: '06:00 AM');
    final repeat = TextEditingController(text: 'daily');

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
            16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
        child: Wrap(
          runSpacing: 12,
          children: [
            Text('Add reminder', style: Theme.of(context).textTheme.titleLarge),
            TextField(
                controller: title,
                decoration: const InputDecoration(labelText: 'Title')),
            TextField(
                controller: message,
                decoration: const InputDecoration(labelText: 'Message')),
            TextField(
                controller: time,
                decoration: const InputDecoration(labelText: 'Scheduled time')),
            TextField(
                controller: repeat,
                decoration: const InputDecoration(
                    labelText: 'Repeat (once/daily/weekly)')),
            ElevatedButton(
              onPressed: () async {
                await ref.read(wellnessControllerProvider.notifier).addReminder(
                      title: title.text.trim(),
                      message: message.text.trim(),
                      scheduledTime: time.text.trim(),
                      repeat: repeat.text.trim().toLowerCase(),
                    );
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Save reminder'),
            ),
          ],
        ),
      ),
    );
  }
}
