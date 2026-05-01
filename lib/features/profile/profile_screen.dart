import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../shared/app_scaffold.dart';
import '../../shared/form_options.dart';
import '../../shared/widgets.dart';
import '../../state/wellness_controller.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(wellnessControllerProvider).requireValue;
    final user = state.currentUser!;
    final controller = ref.read(wellnessControllerProvider.notifier);
    final bmi = controller.calculateBmi(user.weight, user.height);

    return AppScaffold(
      title: 'Profile',
      child: ListView(
        children: [
          SectionCard(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 36,
                  child: Text(
                    user.name.isEmpty ? '?' : user.name[0].toUpperCase(),
                  ),
                ),
                const SizedBox(height: 12),
                Text(user.name, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 4),
                Text(user.email, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
          const SizedBox(height: 14),
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.2,
            children: [
              StatTile(title: 'Age', value: '${user.age}'),
              StatTile(title: 'Gender', value: user.gender),
              StatTile(
                title: 'Height',
                value: '${user.height.toStringAsFixed(0)} cm',
              ),
              StatTile(title: 'BMI', value: bmi.toStringAsFixed(2)),
            ],
          ),
          const SizedBox(height: 14),
          SectionCard(
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.edit_outlined),
                  title: const Text('Edit profile'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showEditProfile(context, ref),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.analytics_outlined),
                  title: const Text('Analytics'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.go('/analytics'),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.monitor_heart_outlined),
                  title: const Text('Health logs'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.go('/health-logs'),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.favorite_border),
                  title: const Text('Vitals & wellness'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.go('/vitals'),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.notifications_outlined),
                  title: const Text('Reminders'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.go('/reminders'),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.settings_outlined),
                  title: const Text('Settings'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.go('/settings'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditProfile(BuildContext context, WidgetRef ref) async {
    final state = ref.read(wellnessControllerProvider).requireValue;
    final user = state.currentUser!;
    final formKey = GlobalKey<FormState>();
    final name = TextEditingController(text: user.name);
    final age = TextEditingController(text: '${user.age}');
    var selectedGender =
        genderOptions.contains(user.gender) ? user.gender : genderOptions.first;
    final height = TextEditingController(text: user.height.toStringAsFixed(0));
    final weight = TextEditingController(text: user.weight.toStringAsFixed(1));

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
                      Row(
                        children: [
                          const Icon(Icons.person_outline),
                          const SizedBox(width: 10),
                          Text(
                            'Edit profile',
                            style: Theme.of(modalContext).textTheme.titleLarge,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: name,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(labelText: 'Name'),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                                ? 'Required'
                                : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: age,
                              decoration:
                                  const InputDecoration(labelText: 'Age'),
                              keyboardType: TextInputType.number,
                              validator: (value) =>
                                  int.tryParse(value?.trim() ?? '') == null
                                      ? 'Enter age'
                                      : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: selectedGender,
                              isExpanded: true,
                              decoration:
                                  const InputDecoration(labelText: 'Gender'),
                              items: genderOptions
                                  .map(
                                    (value) => DropdownMenuItem(
                                      value: value,
                                      child: Text(value),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setModalState(() => selectedGender = value);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: height,
                              decoration: const InputDecoration(
                                  labelText: 'Height (cm)'),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              validator: (value) =>
                                  double.tryParse(value?.trim() ?? '') == null
                                      ? 'Enter height'
                                      : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: weight,
                              decoration: const InputDecoration(
                                  labelText: 'Weight (kg)'),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              validator: (value) =>
                                  double.tryParse(value?.trim() ?? '') == null
                                      ? 'Enter weight'
                                      : null,
                            ),
                          ),
                        ],
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
                                    .updateProfile(
                                      name: name.text.trim(),
                                      age: int.parse(age.text.trim()),
                                      gender: selectedGender,
                                      height: double.parse(height.text.trim()),
                                      weight: double.parse(weight.text.trim()),
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

    name.dispose();
    age.dispose();
    height.dispose();
    weight.dispose();
  }
}
