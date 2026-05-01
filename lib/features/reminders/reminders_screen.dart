import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/notifications/notification_service.dart';
import '../../shared/app_scaffold.dart';
import '../../shared/form_options.dart';
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (!kIsWeb) {
            NotificationService().init();
          }
          _showAddReminder(context, ref);
        },
        label: const Text('Reminder'),
        icon: const Icon(Icons.add_alert_outlined),
      ),
      child: items.isEmpty
          ? const EmptyState(
              title: 'No reminders yet',
              message:
                  'Add healthy routine reminders like workouts, hydration, or weight checks.',
            )
          : ListView.separated(
              padding: const EdgeInsets.only(bottom: 96),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, index) {
                final reminder = items[index];
                return SectionCard(
                  child: SwitchListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    title: Text(
                      reminder.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(reminder.message),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.access_time,
                                size: 16,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${reminder.scheduledTime} - ${optionLabel(reminder.repeat)}',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    value: reminder.isActive,
                    onChanged: (_) => controller.toggleReminder(reminder.id),
                  ),
                );
              },
            ),
    );
  }

  Future<void> _showAddReminder(BuildContext context, WidgetRef ref) async {
    final formKey = GlobalKey<FormState>();
    final title = TextEditingController();
    final message = TextEditingController();
    var selectedTime = const TimeOfDay(hour: 6, minute: 0);
    var selectedRepeat = 'daily';

    await showAppModal<void>(
      context: context,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(18),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Add reminder',
                        style: Theme.of(modalContext).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: title,
                        decoration: const InputDecoration(labelText: 'Title'),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                                ? 'Required'
                                : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: message,
                        minLines: 2,
                        maxLines: 3,
                        decoration: const InputDecoration(labelText: 'Message'),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                                ? 'Required'
                                : null,
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: modalContext,
                            initialTime: selectedTime,
                          );
                          if (picked != null) {
                            setModalState(() => selectedTime = picked);
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Scheduled time',
                            suffixIcon: Icon(Icons.schedule_outlined),
                          ),
                          child: Text(selectedTime.format(modalContext)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: selectedRepeat,
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'Repeat'),
                        items: reminderRepeatOptions
                            .map(
                              (value) => DropdownMenuItem(
                                value: value,
                                child: Text(optionLabel(value)),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setModalState(() => selectedRepeat = value);
                          }
                        },
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(modalContext),
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
                                    .addReminder(
                                      title: title.text.trim(),
                                      message: message.text.trim(),
                                      scheduledTime:
                                          selectedTime.format(modalContext),
                                      repeat: selectedRepeat,
                                    );
                                if (!modalContext.mounted) return;
                                if (error != null) {
                                  ScaffoldMessenger.of(modalContext)
                                      .showSnackBar(
                                    SnackBar(content: Text(error)),
                                  );
                                  return;
                                }
                                Navigator.pop(modalContext);
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
            );
          },
        );
      },
    );

    title.dispose();
    message.dispose();
  }
}
