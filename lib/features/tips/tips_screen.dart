import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/app_scaffold.dart';
import '../../shared/widgets.dart';
import '../../state/wellness_controller.dart';

class TipsScreen extends ConsumerWidget {
  const TipsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tips = ref.watch(wellnessControllerProvider).requireValue.tips;
    return AppScaffold(
      title: 'Health Tips',
      child: ListView.separated(
        itemCount: tips.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, index) {
          final tip = tips[index];
          return SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(tip.title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18))),
                    Chip(label: Text(tip.category)),
                  ],
                ),
                const SizedBox(height: 10),
                Text(tip.summary),
                const SizedBox(height: 12),
                Text(tip.content, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 10),
                Text('Source: ${tip.source}', style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          );
        },
      ),
    );
  }
}
