import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/localization/locale_keys.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_bottom_nav_bar.dart';
import '../../core/widgets/app_top_safe_area.dart';
import '../../core/widgets/deck_card.dart';
import '../../core/widgets/empty_decks_state.dart';
import 'decks_controller.dart';
import 'widgets/deck_stats_row.dart';
import 'widgets/mixed_review_tile.dart';

/// The Decks tab: what you've built, then a way in.
///
/// Ordered so the most common intent is satisfied first. "Study something"
/// is far more common than "open one specific deck", so the totals and the
/// cross-deck session come before the list - the list is the fallback for
/// when you *do* want one deck in particular.
class DecksView extends GetView<DecksController> {
  const DecksView({super.key});

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
              Text(LocaleKeys.homeYourDecks.tr, style: AppTextStyles.heading1),
              const SizedBox(height: AppSpacing.lg),
              Obx(() {
                if (controller.isLoadingDecks.value &&
                    controller.decks.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (controller.decks.isEmpty) {
                  return const EmptyDecksState();
                }
                return _buildContent(context);
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DeckStatsRow(
          deckCount: controller.decks.length,
          wordCount: controller.totalCardCount,
          dueCount: controller.dueCount,
        ),
        const SizedBox(height: AppSpacing.md),
        // Above the list on purpose: the best next session is usually
        // "whatever is owed", not any one deck. Hidden only when there is
        // genuinely nothing to serve, so it never offers a dead tap.
        if (controller.dueCount > 0 || controller.canPractice) ...[
          MixedReviewTile(
            dueCount: controller.dueCount,
            isLoading: controller.isLoadingPractice.value,
            onTap: controller.dueCount > 0
                ? controller.startDueSession
                : controller.startPracticeRound,
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        Text(
          LocaleKeys.decksAll.tr,
          style: AppTextStyles.label.copyWith(color: context.colorInkMuted),
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final deck in controller.decks) ...[
          DeckCard(deck: deck, onTap: () => controller.goToDeck(deck)),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}
