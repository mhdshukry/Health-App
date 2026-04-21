import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/app_scaffold.dart';
import '../../shared/widgets.dart';
import '../../state/wellness_controller.dart';

class HealthLogsScreen extends ConsumerWidget {
  const HealthLogsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(wellnessControllerProvider).requireValue;
    final controller = ref.read(wellnessControllerProvider.notifier);
    final items = controller.userHealthLogs(state).reversed.toList();

    return AppScaffold(
      title: 'Health Logs',
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddLog(context, ref),
        child: const Icon(Icons.add),
      ),
      child: items.isEmpty
          ? const EmptyState(title: 'No health logs yet', message: 'Record your weight and BMI to build progress history.')
          : ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, index) {
                final log = items[index];
                return SectionCard(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${log.weight.toStringAsFixed(1)} kg', style: Theme.of(context).textTheme.titleLarge),
                            const SizedBox(height: 6),
                            Text('BMI ${log.bmi.toStringAsFixed(2)} · ${formatDate(log.date)}'),
                            if (log.notes.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(log.notes, style: Theme.of(context).textTheme.bodyMedium),
                            ],
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.secondary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(_bmiLabel(log.bmi)),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Future<void> _showAddLog(BuildContext context, WidgetRef ref) async {
    final state = ref.read(wellnessControllerProvider).requireValue;
    final user = state.currentUser!;
    final weight = TextEditingController(text: user.weight.toStringAsFixed(1));
    final height = TextEditingController(text: user.height.toStringAsFixed(0));
    final notes = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
        child: Wrap(
          runSpacing: 12,
          children: [
            Text('Add health log', style: Theme.of(context).textTheme.titleLarge),
            TextField(controller: weight, decoration: const InputDecoration(labelText: 'Weight (kg)'), keyboardType: const TextInputType.numberWithOptions(decimal: true)),
            TextField(controller: height, decoration: const InputDecoration(labelText: 'Height (cm)'), keyboardType: const TextInputType.numberWithOptions(decimal: true)),
            TextField(controller: notes, decoration: const InputDecoration(labelText: 'Notes')),
            ElevatedButton(
              onPressed: () async {
                await ref.read(wellnessControllerProvider.notifier).addHealthLog(
                      weight: double.parse(weight.text.trim()),
                      height: double.parse(height.text.trim()),
                      notes: notes.text.trim(),
                      date: DateTime.now(),
                    );
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Save health log'),
            ),
          ],
        ),
      ),
    );
  }

  static String _bmiLabel(double bmi) {
    if (bmi < 18.5) return 'Under';
    if (bmi < 25) return 'Normal';
    if (bmi < 30) return 'Over';
    return 'High';
  }
}
