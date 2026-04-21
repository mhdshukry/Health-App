import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../shared/app_scaffold.dart';
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
                CircleAvatar(radius: 36, child: Text(user.name.isEmpty ? '?' : user.name[0].toUpperCase())),
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
              StatTile(title: 'Height', value: '${user.height.toStringAsFixed(0)} cm'),
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
    final name = TextEditingController(text: user.name);
    final age = TextEditingController(text: '${user.age}');
    final gender = TextEditingController(text: user.gender);
    final height = TextEditingController(text: user.height.toStringAsFixed(0));
    final weight = TextEditingController(text: user.weight.toStringAsFixed(1));

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
        child: Wrap(
          runSpacing: 12,
          children: [
            Text('Edit profile', style: Theme.of(context).textTheme.titleLarge),
            TextField(controller: name, decoration: const InputDecoration(labelText: 'Name')),
            TextField(controller: age, decoration: const InputDecoration(labelText: 'Age'), keyboardType: TextInputType.number),
            TextField(controller: gender, decoration: const InputDecoration(labelText: 'Gender')),
            TextField(controller: height, decoration: const InputDecoration(labelText: 'Height (cm)'), keyboardType: const TextInputType.numberWithOptions(decimal: true)),
            TextField(controller: weight, decoration: const InputDecoration(labelText: 'Weight (kg)'), keyboardType: const TextInputType.numberWithOptions(decimal: true)),
            ElevatedButton(
              onPressed: () async {
                await ref.read(wellnessControllerProvider.notifier).updateProfile(
                      name: name.text.trim(),
                      age: int.parse(age.text.trim()),
                      gender: gender.text.trim(),
                      height: double.parse(height.text.trim()),
                      weight: double.parse(weight.text.trim()),
                    );
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Save profile'),
            ),
          ],
        ),
      ),
    );
  }
}
