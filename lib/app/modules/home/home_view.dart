import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/localization/locale_keys.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_bottom_nav_bar.dart';
import '../../core/widgets/app_top_safe_area.dart';
import '../../core/widgets/deck_card.dart';
import 'home_controller.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppTopSafeArea.height(context),
            AppSpacing.lg,
            AppBottomNavBar.clearance,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                controller.firstName != null
                    ? LocaleKeys.homeGreeting.trParams({
                        'name': controller.firstName!,
                      })
                    : LocaleKeys.homeGreetingGeneric.tr,
                style: AppTextStyles.heading1,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                LocaleKeys.homeSubtitle.tr,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.lg),
              // Reviewing is the daily habit and scanning is occasional,
              // so whichever one is actually owed takes the accent.
              Obx(() {
                final dueCount = controller.decksController.dueCount;
                if (dueCount == 0) {
                  return _ScanCta(
                    onTap: controller.goToScan,
                    isPrimary: true,
                  );
                }
                return Column(
                  children: [
                    _ReviewCta(
                      dueCount: dueCount,
                      onTap: controller.startReview,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _ScanCta(onTap: controller.goToScan, isPrimary: false),
                  ],
                );
              }),
              Obx(() {
                final decksController = controller.decksController;
                if (decksController.decks.isEmpty) {
                  return const SizedBox.shrink();
                }
                final recent = decksController.decks.take(3).toList();
                return Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.lg * 1.5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            LocaleKeys.homeYourDecks.tr,
                            style: AppTextStyles.heading2,
                          ),
                          TextButton(
                            onPressed: controller.goToDecksTab,
                            child: Text(LocaleKeys.homeSeeAll.tr),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      for (final deck in recent) ...[
                        DeckCard(
                          deck: deck,
                          onTap: () => decksController.goToDeck(deck),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                      ],
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

/// The one-tap way into everything that's owed today, regardless of which
/// deck it lives in.
class _ReviewCta extends StatelessWidget {
  const _ReviewCta({required this.dueCount, required this.onTap});

  final int dueCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _HomeCta(
      icon: Icons.style_rounded,
      title: dueCount == 1
          ? LocaleKeys.homeReviewCtaOne.tr
          : LocaleKeys.homeReviewCta.trParams({'count': '$dueCount'}),
      subtitle: LocaleKeys.homeReviewCtaSubtitle.tr,
      isPrimary: true,
      onTap: onTap,
    );
  }
}

class _ScanCta extends StatelessWidget {
  const _ScanCta({required this.onTap, required this.isPrimary});

  final VoidCallback onTap;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    return _HomeCta(
      icon: Icons.document_scanner_rounded,
      title: LocaleKeys.homeScanCtaTitle.tr,
      subtitle: LocaleKeys.homeScanCtaSubtitle.tr,
      isPrimary: isPrimary,
      onTap: onTap,
    );
  }
}

/// Shared shape for Home's two calls to action. Only one of them wears
/// the accent at a time, so the screen always has a single obvious next
/// step rather than two competing orange blocks.
class _HomeCta extends StatelessWidget {
  const _HomeCta({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isPrimary,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool isPrimary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = isPrimary ? Colors.white : context.colorInk;
    final mutedForeground = isPrimary
        ? Colors.white.withValues(alpha: 0.85)
        : context.colorInkMuted;

    return Material(
      color: isPrimary ? AppColors.accent : context.colorSurface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(isPrimary ? AppSpacing.lg : AppSpacing.md),
          child: Row(
            children: [
              Container(
                height: isPrimary ? 48 : 40,
                width: isPrimary ? 48 : 40,
                decoration: BoxDecoration(
                  color: isPrimary
                      ? Colors.white.withValues(alpha: 0.18)
                      : AppColors.accent.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: isPrimary ? 24 : 20,
                  color: isPrimary ? Colors.white : AppColors.accent,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: foreground,
                        fontSize: isPrimary ? 16 : 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTextStyles.caption.copyWith(
                        color: mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_rounded, color: mutedForeground),
            ],
          ),
        ),
      ),
    );
  }
}
