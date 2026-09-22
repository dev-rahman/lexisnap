import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/models/deck.dart';
import '../localization/locale_keys.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// A single deck row, used on both Home's recent-decks preview and the
/// full Decks tab list.
class DeckCard extends StatelessWidget {
  const DeckCard({super.key, required this.deck, required this.onTap});

  final Deck deck;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colorSurface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: context.colorPaper,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.style_outlined,
                  color: context.colorInkMuted,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      deck.name,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: context.colorInk,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      LocaleKeys.homeDeckCardCount.trParams({
                        'count': '${deck.cardCount}',
                      }),
                      style: AppTextStyles.caption.copyWith(
                        color: context.colorInkMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: context.colorInkMuted),
            ],
          ),
        ),
      ),
    );
  }
}
