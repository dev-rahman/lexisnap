import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/localization/locale_keys.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

/// Starts one session drawn from every deck at once, sitting above the
/// deck list as its own row.
///
/// The decks list invites you to pick a deck, which is exactly the
/// decision the scheduler already made for you. This row is the way out
/// of that: cards from wherever they're owed, shuffled together. When
/// nothing is owed it offers a short practice round instead of vanishing,
/// so the entry point doesn't move around depending on the day.
class MixedReviewTile extends StatelessWidget {
  const MixedReviewTile({
    super.key,
    required this.dueCount,
    required this.isLoading,
    required this.onTap,
  });

  final int dueCount;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasDue = dueCount > 0;

    return Material(
      color: hasDue ? AppColors.accentHue.tint(context) : context.colorSurface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: isLoading ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: hasDue ? AppColors.accent : context.colorPaper,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.shuffle_rounded,
                  color: hasDue ? Colors.white : context.colorInkMuted,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      LocaleKeys.decksMixedTitle.tr,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: context.colorInk,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hasDue
                          ? LocaleKeys.decksMixedDue.trParams({
                              'count': '$dueCount',
                            })
                          : LocaleKeys.decksMixedPractice.tr,
                      style: AppTextStyles.caption.copyWith(
                        color: hasDue
                            ? AppColors.accent
                            : context.colorInkMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (isLoading)
                const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(
                  Icons.play_arrow_rounded,
                  color: hasDue ? AppColors.accent : context.colorInkMuted,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
