import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/localization/locale_keys.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

/// Three numbers about the whole collection, above the list.
///
/// The Decks tab used to open on a bare title and a stack of rows, which
/// answered "which deck?" but never "how am I doing?" - so the honest
/// answer to how much you've built was to count the rows yourself.
///
/// Each tile owns a hue rather than sharing one. Three numbers in three
/// colours are three separate facts at a glance; three numbers in one
/// colour is a paragraph you have to read.
class DeckStatsRow extends StatelessWidget {
  const DeckStatsRow({
    super.key,
    required this.deckCount,
    required this.wordCount,
    required this.dueCount,
  });

  final int deckCount;
  final int wordCount;
  final int dueCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatTile(
            hue: AppColors.violet,
            icon: Icons.style_rounded,
            value: deckCount,
            label: LocaleKeys.decksStatDecks.tr,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _StatTile(
            hue: AppColors.teal,
            icon: Icons.translate_rounded,
            value: wordCount,
            label: LocaleKeys.decksStatWords.tr,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _StatTile(
            // Due is the one of the three that asks for action, so it
            // borrows the action colour instead of a hue.
            hue: AppColors.accentHue,
            icon: Icons.bolt_rounded,
            value: dueCount,
            label: LocaleKeys.decksStatDue.tr,
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.hue,
    required this.icon,
    required this.value,
    required this.label,
  });

  final AppHue hue;
  final IconData icon;
  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final color = hue.resolve(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: hue.tint(context),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: AppSpacing.sm),
          // A tile is a third of the screen wide, so a five-figure word
          // count would overflow it at display size. Scaling down beats
          // both clipping and ellipsising a number.
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '$value',
              style: AppTextStyles.display.copyWith(color: context.colorInk),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.label.copyWith(color: context.colorInkMuted),
          ),
        ],
      ),
    );
  }
}
