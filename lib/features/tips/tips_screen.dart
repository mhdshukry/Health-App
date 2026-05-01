import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../models/entities.dart';
import '../../shared/app_scaffold.dart';
import '../../shared/widgets.dart';
import '../../state/wellness_controller.dart';

class TipsScreen extends ConsumerStatefulWidget {
  const TipsScreen({super.key});

  @override
  ConsumerState<TipsScreen> createState() => _TipsScreenState();
}

class _TipsScreenState extends ConsumerState<TipsScreen> {
  bool _loadingExternal = false;
  bool _loadedOnce = false;
  String? _statusMessage;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loadedOnce) return;
    _loadedOnce = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _refreshExternalTips(showMessage: false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final tips = ref.watch(wellnessControllerProvider).requireValue.tips;
    final usingExternal =
        tips.any((tip) => tip.source.toLowerCase().contains('myhealthfinder'));

    return AppScaffold(
      title: 'Health Tips',
      child: ListView.separated(
        itemCount: tips.length + 1,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, index) {
          if (index == 0) {
            return _TipsStatusCard(
              loading: _loadingExternal,
              usingExternal: usingExternal,
              statusMessage: _statusMessage,
              onRefresh: () => _refreshExternalTips(showMessage: true),
            );
          }

          return _TipCard(tip: tips[index - 1]);
        },
      ),
    );
  }

  Future<void> _refreshExternalTips({required bool showMessage}) async {
    if (_loadingExternal) return;
    setState(() {
      _loadingExternal = true;
      _statusMessage = null;
    });

    final message = await ref
        .read(wellnessControllerProvider.notifier)
        .refreshExternalTips();

    if (!mounted) return;
    setState(() {
      _loadingExternal = false;
      _statusMessage = message ?? 'External health tips loaded successfully.';
    });

    if (showMessage) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_statusMessage!)),
      );
    }
  }
}

class _TipsStatusCard extends StatelessWidget {
  const _TipsStatusCard({
    required this.loading,
    required this.usingExternal,
    required this.statusMessage,
    required this.onRefresh,
  });

  final bool loading;
  final bool usingExternal;
  final String? statusMessage;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final color = usingExternal ? AppColors.primary : AppColors.coral;
    final title = usingExternal ? 'External tips active' : 'Cached tips shown';
    final message = loading
        ? 'Fetching evidence-based topics from MyHealthfinder...'
        : statusMessage ??
            (usingExternal
                ? 'Tips are loaded from the ODPHP MyHealthfinder external API.'
                : 'Start the backend and refresh to load external API tips.');

    return SectionCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: color.withOpacity(0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              usingExternal ? Icons.public_outlined : Icons.cloud_off_outlined,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(message, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Refresh tips',
            onPressed: loading ? null : onRefresh,
            icon: loading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
          ),
        ],
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  const _TipCard({required this.tip});

  final HealthTip tip;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 180, maxWidth: 420),
                child: Text(
                  tip.title,
                  softWrap: true,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontSize: 18),
                ),
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 190),
                child: Chip(
                  visualDensity: VisualDensity.compact,
                  label: Text(
                    tip.category,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(tip.summary),
          const SizedBox(height: 12),
          Text(tip.content, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: AppColors.cardAlt,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              'Source: ${tip.source}',
              style: Theme.of(context).textTheme.bodyMedium,
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }
}
