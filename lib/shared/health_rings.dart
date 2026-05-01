import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import 'widgets.dart';

class HealthRingData {
  const HealthRingData({
    required this.label,
    required this.value,
    required this.target,
    required this.unit,
    required this.color,
    required this.icon,
  });

  final String label;
  final double value;
  final double target;
  final String unit;
  final Color color;
  final IconData icon;
}

class HealthRingsCard extends StatelessWidget {
  const HealthRingsCard({
    super.key,
    required this.title,
    required this.rings,
  });

  final String title;
  final List<HealthRingData> rings;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 420;
              return Wrap(
                spacing: 14,
                runSpacing: 14,
                children: rings
                    .map(
                      (ring) => SizedBox(
                        width: compact
                            ? (constraints.maxWidth - 14) / 2
                            : (constraints.maxWidth - 42) / 4,
                        child: _HealthRingTile(data: ring),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _HealthRingTile extends StatelessWidget {
  const _HealthRingTile({required this.data});

  final HealthRingData data;

  @override
  Widget build(BuildContext context) {
    final progress = data.target == 0 ? 0.0 : data.value / data.target;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardAlt,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 86,
            height: 86,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 86,
                  height: 86,
                  child: CircularProgressIndicator(
                    value: progress.clamp(0, 1).toDouble(),
                    strokeWidth: 10,
                    strokeCap: StrokeCap.round,
                    backgroundColor: AppColors.border,
                    color: data.color,
                  ),
                ),
                Icon(data.icon, color: data.color, size: 28),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(data.label, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            '${_compactNumber(data.value)} / ${_compactNumber(data.target)} ${data.unit}',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  static String _compactNumber(double value) {
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}k';
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    return value.toStringAsFixed(1);
  }
}
