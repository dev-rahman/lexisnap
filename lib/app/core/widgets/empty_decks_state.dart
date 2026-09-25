import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../localization/locale_keys.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Shown wherever a deck list would otherwise be empty - the Decks tab
/// and Home both use it, so a new user never meets a blank half-screen.
class EmptyDecksState extends StatelessWidget {
  const EmptyDecksState({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.lg * 1.5,
        horizontal: AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: context.colorSurface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        children: [
          Container(
            height: 64,
            width: 64,
            decoration: BoxDecoration(
              color: context.colorPaper,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.style_outlined,
              color: context.colorInkMuted,
              size: 28,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            LocaleKeys.homeNoDecksTitle.tr,
            style: AppTextStyles.bodyMedium.copyWith(color: context.colorInk),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            LocaleKeys.homeNoDecksBody.tr,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
