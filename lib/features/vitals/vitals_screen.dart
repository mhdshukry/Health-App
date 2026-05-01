import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../models/entities.dart';
import '../../shared/app_scaffold.dart';
import '../../shared/form_options.dart';
import '../../shared/widgets.dart';
import '../../state/wellness_controller.dart';

class VitalsScreen extends ConsumerWidget {
  const VitalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(wellnessControllerProvider).requireValue;
    final controller = ref.read(wellnessControllerProvider.notifier);
    final items = controller.userVitals(state);

    return AppScaffold(
      title: 'Vitals & Wellness',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddVital(context),
        icon: const Icon(Icons.add),
        label: const Text('Log'),
      ),
      child: items.isEmpty
          ? const EmptyState(
              title: 'No wellness logs yet',
              message:
                  'Track blood pressure, hydration, sleep, mood, pain, and other daily health signals.',
            )
          : ListView.separated(
              padding: const EdgeInsets.only(bottom: 96),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) =>
                  _VitalLogCard(item: items[index]),
            ),
    );
  }

  Future<void> _showAddVital(BuildContext context) {
    return showAppModal<void>(
      context: context,
      builder: (_) => const _VitalSheet(),
    );
  }
}

class _VitalLogCard extends StatelessWidget {
  const _VitalLogCard({required this.item});

  final VitalLog item;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: AppColors.cardAlt,
            child: Icon(_categoryIcon(item.category), color: AppColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  optionLabel(item.category),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                Text(_summary(item)),
                const SizedBox(height: 6),
                Text(
                  formatDateTime(item.date),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (item.notes.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    item.notes,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VitalSheet extends ConsumerStatefulWidget {
  const _VitalSheet();

  @override
  ConsumerState<_VitalSheet> createState() => _VitalSheetState();
}

class _VitalSheetState extends ConsumerState<_VitalSheet> {
  final _formKey = GlobalKey<FormState>();
  final _systolic = TextEditingController();
  final _diastolic = TextEditingController();
  final _heartRate = TextEditingController();
  final _bloodGlucose = TextEditingController();
  final _oxygen = TextEditingController();
  final _temperature = TextEditingController();
  final _water = TextEditingController();
  final _sleep = TextEditingController();
  final _pain = TextEditingController();
  final _notes = TextEditingController();
  String _category = vitalCategoryOptions.first;
  String _mood = moodOptions.first;
  DateTime _date = DateTime.now();
  bool _saving = false;

  @override
  void dispose() {
    for (final controller in [
      _systolic,
      _diastolic,
      _heartRate,
      _bloodGlucose,
      _oxygen,
      _temperature,
      _water,
      _sleep,
      _pain,
      _notes,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                      'Add wellness log',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              DropdownButtonFormField<String>(
                value: _category,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Category'),
                items: vitalCategoryOptions
                    .map(
                      (value) => DropdownMenuItem(
                        value: value,
                        child: Text(optionLabel(value)),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _category = value);
                },
              ),
              const SizedBox(height: 12),
              ..._categoryFields(),
              const SizedBox(height: 12),
              InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date and time',
                    suffixIcon: Icon(Icons.event_outlined),
                  ),
                  child: Text(DateFormat('dd MMM yyyy, hh:mm a').format(_date)),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notes,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  hintText: 'Optional context',
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

  List<Widget> _categoryFields() {
    switch (_category) {
      case 'blood_pressure':
        return [
          Row(
            children: [
              Expanded(
                child: _NumberField(
                  controller: _systolic,
                  label: 'Systolic',
                  suffix: 'mmHg',
                  min: 60,
                  max: 260,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _NumberField(
                  controller: _diastolic,
                  label: 'Diastolic',
                  suffix: 'mmHg',
                  min: 40,
                  max: 160,
                ),
              ),
            ],
          ),
        ];
      case 'heart_rate':
        return [
          _NumberField(
              controller: _heartRate, label: 'Heart rate', suffix: 'bpm')
        ];
      case 'blood_glucose':
        return [
          _NumberField(
            controller: _bloodGlucose,
            label: 'Blood glucose',
            suffix: 'mg/dL',
            min: 40,
            max: 500,
          )
        ];
      case 'oxygen':
        return [
          _NumberField(
            controller: _oxygen,
            label: 'Oxygen saturation',
            suffix: '%',
            min: 50,
            max: 100,
          )
        ];
      case 'temperature':
        return [
          _NumberField(
            controller: _temperature,
            label: 'Temperature',
            suffix: 'C',
            min: 30,
            max: 45,
          )
        ];
      case 'hydration':
        return [
          _NumberField(
            controller: _water,
            label: 'Water intake',
            suffix: 'ml',
            min: 1,
            max: 5000,
          )
        ];
      case 'sleep':
        return [
          _NumberField(
            controller: _sleep,
            label: 'Sleep duration',
            suffix: 'hours',
            min: 0.01,
            max: 24,
          )
        ];
      case 'mood':
        return [
          DropdownButtonFormField<String>(
            value: _mood,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Mood'),
            items: moodOptions
                .map((value) =>
                    DropdownMenuItem(value: value, child: Text(value)))
                .toList(),
            onChanged: (value) {
              if (value != null) setState(() => _mood = value);
            },
          ),
        ];
      case 'pain':
        return [
          _NumberField(
            controller: _pain,
            label: 'Pain level',
            suffix: '/ 10',
            min: 0,
            max: 10,
          )
        ];
      default:
        return const [];
    }
  }

  Future<void> _pickDate() async {
    final day = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 3650)),
      lastDate: DateTime.now(),
    );
    if (day == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_date),
    );
    if (time == null || !mounted) return;
    setState(() {
      _date = DateTime(day.year, day.month, day.day, time.hour, time.minute);
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final error =
        await ref.read(wellnessControllerProvider.notifier).addVitalLog(
              category: _category,
              systolic: _number(_systolic),
              diastolic: _number(_diastolic),
              heartRate: _number(_heartRate),
              bloodGlucose: _number(_bloodGlucose),
              oxygenSaturation: _number(_oxygen),
              temperature: _number(_temperature),
              waterMl: _number(_water),
              sleepHours: _number(_sleep),
              mood: _category == 'mood' ? _mood : null,
              painLevel: _number(_pain),
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

  double? _number(TextEditingController controller) {
    final raw = controller.text.trim();
    return raw.isEmpty ? null : double.tryParse(raw);
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.controller,
    required this.label,
    required this.suffix,
    this.min = 1,
    this.max = 300,
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
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
      ],
      decoration: InputDecoration(labelText: label, suffixText: suffix),
      validator: (value) {
        final number = double.tryParse(value?.trim() ?? '');
        if (number == null) return 'Required';
        if (number < min || number > max) {
          return '${min.toStringAsFixed(min < 1 ? 2 : 0)}-${max.toStringAsFixed(0)}';
        }
        return null;
      },
    );
  }
}

IconData _categoryIcon(String category) {
  switch (category) {
    case 'blood_pressure':
      return Icons.bloodtype_outlined;
    case 'heart_rate':
      return Icons.favorite_border;
    case 'blood_glucose':
      return Icons.water_drop_outlined;
    case 'oxygen':
      return Icons.air_outlined;
    case 'temperature':
      return Icons.thermostat_outlined;
    case 'hydration':
      return Icons.local_drink_outlined;
    case 'sleep':
      return Icons.bedtime_outlined;
    case 'mood':
      return Icons.mood_outlined;
    case 'pain':
      return Icons.healing_outlined;
    default:
      return Icons.monitor_heart_outlined;
  }
}

String _summary(VitalLog item) {
  switch (item.category) {
    case 'blood_pressure':
      return '${item.systolic?.toStringAsFixed(0) ?? '-'} / ${item.diastolic?.toStringAsFixed(0) ?? '-'} mmHg';
    case 'heart_rate':
      return '${item.heartRate?.toStringAsFixed(0) ?? '-'} bpm';
    case 'blood_glucose':
      return '${item.bloodGlucose?.toStringAsFixed(0) ?? '-'} mg/dL';
    case 'oxygen':
      return '${item.oxygenSaturation?.toStringAsFixed(0) ?? '-'}% SpO2';
    case 'temperature':
      return '${item.temperature?.toStringAsFixed(1) ?? '-'} C';
    case 'hydration':
      return '${item.waterMl?.toStringAsFixed(0) ?? '-'} ml';
    case 'sleep':
      return '${item.sleepHours?.toStringAsFixed(1) ?? '-'} hours';
    case 'mood':
      return item.mood ?? '-';
    case 'pain':
      return '${item.painLevel?.toStringAsFixed(0) ?? '-'} / 10';
    default:
      return item.notes.isEmpty ? '-' : item.notes;
  }
}
