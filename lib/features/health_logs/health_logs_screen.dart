import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../models/entities.dart';
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddLog(context),
        icon: const Icon(Icons.add),
        label: const Text('Log'),
      ),
      child: items.isEmpty
          ? const EmptyState(
              title: 'No health logs yet',
              message: 'Record weight and BMI to build your progress history.',
            )
          : ListView.separated(
              padding: const EdgeInsets.only(bottom: 96),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, index) => _HealthLogCard(log: items[index]),
            ),
    );
  }

  Future<void> _showAddLog(BuildContext context) {
    return showAppModal<void>(
      context: context,
      builder: (_) => const _HealthLogSheet(),
    );
  }
}

class _HealthLogCard extends StatelessWidget {
  const _HealthLogCard({required this.log});

  final HealthLog log;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: _bmiColor(log.bmi).withOpacity(0.14),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.monitor_weight_outlined,
              color: _bmiColor(log.bmi),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${log.weight.toStringAsFixed(1)} kg',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    _BmiChip(bmi: log.bmi),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'BMI ${log.bmi.toStringAsFixed(1)} - ${formatDate(log.date)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  'Height ${log.height.toStringAsFixed(0)} cm',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (log.notes.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(log.notes),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HealthLogSheet extends ConsumerStatefulWidget {
  const _HealthLogSheet();

  @override
  ConsumerState<_HealthLogSheet> createState() => _HealthLogSheetState();
}

class _HealthLogSheetState extends ConsumerState<_HealthLogSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _weight;
  late final TextEditingController _height;
  final _notes = TextEditingController();
  DateTime _date = DateTime.now();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(wellnessControllerProvider).requireValue.currentUser!;
    _weight = TextEditingController(text: user.weight.toStringAsFixed(1));
    _height = TextEditingController(text: user.height.toStringAsFixed(0));
    _weight.addListener(_refreshPreview);
    _height.addListener(_refreshPreview);
  }

  @override
  void dispose() {
    _weight
      ..removeListener(_refreshPreview)
      ..dispose();
    _height
      ..removeListener(_refreshPreview)
      ..dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final previewBmi = _previewBmi;
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  height: 4,
                  width: 44,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  const Icon(Icons.monitor_heart_outlined,
                      color: AppColors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Add health log',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              if (previewBmi != null) _BmiPreview(bmi: previewBmi),
              if (previewBmi != null) const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _NumberField(
                      controller: _weight,
                      label: 'Weight',
                      suffix: 'kg',
                      min: 20,
                      max: 350,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _NumberField(
                      controller: _height,
                      label: 'Height',
                      suffix: 'cm',
                      min: 80,
                      max: 250,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date',
                    suffixIcon: Icon(Icons.calendar_today_outlined),
                  ),
                  child: Text(DateFormat('dd MMM yyyy').format(_date)),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notes,
                minLines: 2,
                maxLines: 4,
                textInputAction: TextInputAction.newline,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  hintText: 'How do you feel today?',
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          _saving ? null : () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Save'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  double? get _previewBmi {
    final weight = double.tryParse(_weight.text.trim());
    final height = double.tryParse(_height.text.trim());
    if (weight == null || height == null || height <= 0) return null;
    final heightM = height / 100;
    return double.parse((weight / (heightM * heightM)).toStringAsFixed(1));
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 3650)),
      lastDate: DateTime.now(),
    );
    if (picked != null && mounted) {
      setState(() => _date = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final error =
        await ref.read(wellnessControllerProvider.notifier).addHealthLog(
              weight: double.parse(_weight.text.trim()),
              height: double.parse(_height.text.trim()),
              notes: _notes.text.trim(),
              date: _date,
            );
    if (!mounted) return;
    setState(() => _saving = false);
    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    Navigator.of(context).pop();
  }

  void _refreshPreview() {
    if (mounted) setState(() {});
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.controller,
    required this.label,
    required this.suffix,
    required this.min,
    required this.max,
  });

  final TextEditingController controller;
  final String label;
  final String suffix;
  final double min;
  final double max;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,1}')),
      ],
      decoration: InputDecoration(labelText: label, suffixText: suffix),
      validator: (value) {
        final number = double.tryParse(value?.trim() ?? '');
        if (number == null) return 'Required';
        if (number < min || number > max) {
          return '${min.toStringAsFixed(0)}-${max.toStringAsFixed(0)}';
        }
        return null;
      },
    );
  }
}

class _BmiPreview extends StatelessWidget {
  const _BmiPreview({required this.bmi});

  final double bmi;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardAlt,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: _bmiColor(bmi).withOpacity(0.16),
            child: Icon(Icons.speed_outlined, color: _bmiColor(bmi)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BMI ${bmi.toStringAsFixed(1)}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(_bmiDescription(bmi)),
              ],
            ),
          ),
          _BmiChip(bmi: bmi),
        ],
      ),
    );
  }
}

class _BmiChip extends StatelessWidget {
  const _BmiChip({required this.bmi});

  final double bmi;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: _bmiColor(bmi).withOpacity(0.14),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        _bmiLabel(bmi),
        style: TextStyle(color: _bmiColor(bmi), fontWeight: FontWeight.w700),
      ),
    );
  }
}

String _bmiLabel(double bmi) {
  if (bmi < 18.5) return 'Under';
  if (bmi < 25) return 'Normal';
  if (bmi < 30) return 'Over';
  return 'High';
}

String _bmiDescription(double bmi) {
  if (bmi < 18.5) return 'Below the usual healthy BMI range.';
  if (bmi < 25) return 'Inside the usual healthy BMI range.';
  if (bmi < 30) return 'Above the usual healthy BMI range.';
  return 'High BMI range. Track trends and goals carefully.';
}

Color _bmiColor(double bmi) {
  if (bmi < 18.5) return const Color(0xFF6EA8FE);
  if (bmi < 25) return AppColors.primary;
  if (bmi < 30) return const Color(0xFFFFC857);
  return AppColors.coral;
}
