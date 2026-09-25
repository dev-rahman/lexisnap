import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/localization/locale_keys.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_bottom_nav_bar.dart';
import '../../core/widgets/app_top_safe_area.dart';
import '../../core/widgets/deck_card.dart';
import '../../core/widgets/empty_decks_state.dart';
import 'home_controller.dart';
import 'widgets/scan_tile.dart';
import 'widgets/today_hero_card.dart';

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
              Obx(() {
                final decks = controller.decksController;
                return TodayHeroCard(
                  streak: controller.streakService.streak.value,
                  weekProgress: controller.streakService.weekProgress,
                  dueCount: decks.dueCount,
                  reviewMinutes: controller.reviewMinutes,
                  mode: controller.studyPreferences.mode.value,
                  previousGoalProgress: controller.previousGoalProgress.value,
                  replayToken: controller.heroReplayToken.value,
                  hasDecks: decks.decks.isNotEmpty,
                  isLoading: decks.isLoadingDecks.value,
                  onStart: controller.startSession,
                );
              }),
              const SizedBox(height: AppSpacing.md),
              ScanTile(onTap: controller.goToScan),
              Obx(() {
                final decks = controller.decksController;
                if (decks.isLoadingDecks.value && decks.decks.isEmpty) {
                  return const SizedBox.shrink();
                }

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
                          if (decks.decks.isNotEmpty)
                            TextButton(
                              onPressed: controller.goToDecksTab,
                              child: Text(LocaleKeys.homeSeeAll.tr),
                            ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      if (decks.decks.isEmpty)
                        const EmptyDecksState()
                      else
                        for (final deck in decks.decks.take(3)) ...[
                          DeckCard(
                            deck: deck,
                            onTap: () => decks.goToDeck(deck),
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
