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
              _ScanCta(onTap: controller.goToScan),
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

class _ScanCta extends StatelessWidget {
  const _ScanCta({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.accent,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.document_scanner_rounded,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      LocaleKeys.homeScanCtaTitle.tr,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      LocaleKeys.homeScanCtaSubtitle.tr,
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_rounded, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}
