import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../state/wellness_controller.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _controller = PageController();
  int index = 0;

  final slides = const [
    _SlideData(icon: Icons.monitor_heart_outlined, title: 'Track your health', subtitle: 'Monitor steps, workouts, weight, and BMI in one place.'),
    _SlideData(icon: Icons.flag_outlined, title: 'Manage your goals', subtitle: 'Set measurable wellness goals and watch your progress grow.'),
    _SlideData(icon: Icons.notifications_active_outlined, title: 'Get smart reminders', subtitle: 'Keep routines consistent with reminder schedules that fit your day.'),
    _SlideData(icon: Icons.insights_outlined, title: 'View analytics and tips', subtitle: 'Use visual charts and curated health tips to improve decisions.'),
  ];

  @override
  Widget build(BuildContext context) {
    final isLast = index == slides.length - 1;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () async {
                    await ref.read(wellnessControllerProvider.notifier).completeOnboarding();
                    if (mounted) context.go('/login');
                  },
                  child: const Text('Skip'),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: slides.length,
                  onPageChanged: (value) => setState(() => index = value),
                  itemBuilder: (_, i) {
                    final slide = slides[i];
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(42),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Icon(slide.icon, color: AppColors.primary, size: 84),
                        ),
                        const SizedBox(height: 28),
                        Text(slide.title, style: Theme.of(context).textTheme.headlineMedium, textAlign: TextAlign.center),
                        const SizedBox(height: 14),
                        Text(slide.subtitle, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.muted)),
                      ],
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  slides.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: i == index ? 28 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i == index ? AppColors.primary : AppColors.slate,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              ElevatedButton(
                onPressed: () async {
                  if (isLast) {
                    await ref.read(wellnessControllerProvider.notifier).completeOnboarding();
                    if (mounted) context.go('/login');
                  } else {
                    _controller.nextPage(duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
                  }
                },
                child: Text(isLast ? 'Get Started' : 'Next'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SlideData {
  const _SlideData({required this.icon, required this.title, required this.subtitle});
  final IconData icon;
  final String title;
  final String subtitle;
}
