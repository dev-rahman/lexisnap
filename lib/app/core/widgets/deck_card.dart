import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/models/deck.dart';
import '../localization/locale_keys.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'deck_badge.dart';

/// A single deck row, used on both Home's recent-decks preview and the
/// full Decks tab list.
///
/// Each deck carries its own hue, derived from its id so it never changes
/// (see [AppColors.hueFor]). A list of decks is something you scan for the
/// one you want, and colour turns that from reading every row into
/// recognising one - which is the whole job of this screen.
///
/// Only the icon tile is saturated. Washing the whole card in the hue
/// would make six decks read as six warnings, and nothing on the screen
/// would be quiet enough for the deck name to matter.
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
              DeckBadge(deckId: deck.id),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      deck.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.heading3.copyWith(
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
