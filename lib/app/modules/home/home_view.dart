import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/localization/locale_keys.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_bottom_nav_bar.dart';
import '../../core/widgets/app_shell_buttons.dart';
import '../../core/widgets/app_top_safe_area.dart';
import '../../core/widgets/deck_card.dart';
import '../../core/widgets/empty_decks_state.dart';
import '../../core/widgets/scan_source_sheet.dart';
import 'home_controller.dart';
import 'widgets/scan_tile.dart';
import 'widgets/today_hero_card.dart';
import 'widgets/week_card.dart';

/// Home, read top to bottom: who you are and how you're doing, what to do
/// about it today, the week behind it, then a way to add more.
///
/// The hero panel is about one decision, so the streak and the week live
/// together in the card below it rather than crowding in alongside.
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
            AppBottomNavBar.clearanceFor(context),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGreeting(context),
              const SizedBox(height: AppSpacing.lg),
              Obx(() {
                final decks = controller.decksController;
                return TodayHeroCard(
                  streak: controller.streakService.streak.value,
                  sessionSize: controller.reviewSessionSize,
                  reviewMinutes: controller.reviewMinutes,
                  mode: controller.studyPreferences.mode.value,
                  previousGoalProgress: controller.previousGoalProgress.value,
                  replayToken: controller.heroReplayToken.value,
                  hasDecks: decks.decks.isNotEmpty,
                  isLoading: decks.isLoadingDecks.value,
                  onStart: controller.startSession,
                  canPractice: decks.canPractice,
                  practiceCount: controller.practiceRoundSize,
                  isLoadingPractice: decks.isLoadingPractice.value,
                  onPractice: controller.startPractice,
                );
              }),
              const SizedBox(height: AppSpacing.md),
              Obx(
                () => WeekCard(
                  days: controller.streakService.weekProgress,
                  streak: controller.streakService.streak.value,
                  replayToken: controller.heroReplayToken.value,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              ScanTile(onTap: () => startScanFlow(context)),
              _buildDecks(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGreeting(BuildContext context) {
    // The account avatar floats over this corner from the app shell, so the
    // greeting has to stop short of it. A long first name used to run
    // straight underneath the avatar, and the streak pill that briefly
    // lived here was hidden by it outright.
    return Padding(
      padding: const EdgeInsets.only(right: AppShellButton.clearance),
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
        ],
      ),
    );
  }

  Widget _buildDecks() {
    return Obx(() {
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
                DeckCard(deck: deck, onTap: () => decks.goToDeck(deck)),
                const SizedBox(height: AppSpacing.sm),
              ],
          ],
        ),
      );
    });
  }
}
