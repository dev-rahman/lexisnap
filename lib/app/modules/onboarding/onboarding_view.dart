import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_button.dart';
import 'onboarding_controller.dart';

class OnboardingView extends GetView<OnboardingController> {
  const OnboardingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Image.asset('assets/images/lexisnap_wordmark.png', height: 36),
                  TextButton(
                    onPressed: controller.complete,
                    child: const Text('Skip'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: controller.pageController,
                onPageChanged: controller.onPageChanged,
                itemCount: OnboardingController.pages.length,
                itemBuilder: (context, index) {
                  final page = OnboardingController.pages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _OnboardingIllustration(icon: page.icon),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          page.title,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.heading1,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          page.description,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Obx(
              () => Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  OnboardingController.pages.length,
                  (index) => _PageDot(isActive: controller.currentPage.value == index),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Obx(
                () => AppButton(
                  label: controller.isLastPage ? 'Get started' : 'Next',
                  onPressed: controller.next,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingIllustration extends StatelessWidget {
  const _OnboardingIllustration({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      width: 220,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 72, color: AppColors.ink),
            const SizedBox(height: AppSpacing.md),
            Container(
              height: 6,
              width: 64,
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PageDot extends StatelessWidget {
  const _PageDot({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 8,
      width: isActive ? 24 : 8,
      decoration: BoxDecoration(
        color: isActive ? AppColors.accent : AppColors.border,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
    );
  }
}
