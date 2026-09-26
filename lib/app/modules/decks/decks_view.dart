import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/localization/locale_keys.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_bottom_nav_bar.dart';
import '../../core/widgets/app_top_safe_area.dart';
import '../../core/widgets/deck_card.dart';
import '../../core/widgets/empty_decks_state.dart';
import 'decks_controller.dart';
import 'widgets/mixed_review_tile.dart';

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
            AppBottomNavBar.clearance,
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
                return Column(
                  children: [
                    // Above the list on purpose: the best next session is
                    // usually "whatever is owed", not any one deck. Hidden
                    // only when there is genuinely nothing to serve, so it
                    // never offers a tap that does nothing.
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
                    for (final deck in controller.decks) ...[
                      DeckCard(
                        deck: deck,
                        onTap: () => controller.goToDeck(deck),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
