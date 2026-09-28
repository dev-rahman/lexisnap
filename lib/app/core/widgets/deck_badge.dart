import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';

/// A deck's colour, as a filled tile with the deck glyph in it.
///
/// Shared between the deck rows and a deck's own screen on purpose: the
/// hue is how you recognise a deck, so it has to be the same mark in both
/// places. Seeing a teal tile in the list and a grey heading after tapping
/// it would make the colour decorative instead of meaningful.
class DeckBadge extends StatelessWidget {
  const DeckBadge({super.key, required this.deckId, this.size = 46});

  /// Seeds the hue, so a deck keeps its colour for life.
  final String deckId;

  final double size;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.hueFor(deckId).resolve(context);

    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Icon(Icons.style_rounded, color: Colors.white, size: size * 0.48),
    );
  }
}
