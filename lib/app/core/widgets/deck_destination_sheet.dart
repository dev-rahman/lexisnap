import 'package:flutter/material.dart';

import '../../data/models/deck.dart';
import '../../data/vocabulary_languages.dart';
import '../localization/locale_keys.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'app_bottom_sheet.dart';

import 'package:get/get.dart';

/// Where a batch of scanned words should land: a brand-new deck, or one the
/// user already has. The scan flow asks for this after the words are picked
/// (see [showDeckDestinationSheet]) so a single scan can start a deck, top
/// up an existing one, or be split across several across repeated choices.
sealed class DeckDestination {
  const DeckDestination();
}

/// Create a fresh deck. The caller still asks for a target language before
/// saving, since a new deck has none yet.
class NewDeckDestination extends DeckDestination {
  const NewDeckDestination();
}

/// Append to [deck]. Its own target language is reused, so no language step
/// is needed.
class ExistingDeckDestination extends DeckDestination {
  const ExistingDeckDestination(this.deck);

  final Deck deck;
}

/// Asks where [wordCount] selected words should go. Returns the chosen
/// destination, or null if the sheet was dismissed without a choice.
///
/// [decks] is the user's existing decks, shown under the "new deck" option.
/// When it is empty the sheet is effectively a confirm step for a new deck.
///
/// Reused beyond scanning: [title] and [subtitle] override the default
/// "Add N words to…" wording (moving and copying cards pass their own), and
/// [allowNewDeck] hides the "new deck" option when only existing decks make
/// sense as a destination.
Future<DeckDestination?> showDeckDestinationSheet(
  BuildContext context, {
  required List<Deck> decks,
  required int wordCount,
  String? title,
  String? subtitle,
  bool allowNewDeck = true,
}) {
  return showAppSheet<DeckDestination>(
    context,
    isScrollControlled: true,
    maxHeightFraction: 0.85,
    builder: (sheetContext) => _DeckDestinationSheet(
      decks: decks,
      wordCount: wordCount,
      title: title,
      subtitle: subtitle,
      allowNewDeck: allowNewDeck,
    ),
  );
}

class _DeckDestinationSheet extends StatefulWidget {
  const _DeckDestinationSheet({
    required this.decks,
    required this.wordCount,
    this.title,
    this.subtitle,
    this.allowNewDeck = true,
  });

  final List<Deck> decks;
  final int wordCount;
  final String? title;
  final String? subtitle;
  final bool allowNewDeck;

  @override
  State<_DeckDestinationSheet> createState() => _DeckDestinationSheetState();
}

class _DeckDestinationSheetState extends State<_DeckDestinationSheet> {
  /// Above this many decks, scanning the list by eye gets slow, so a search
  /// field earns its space; below it, the field is just noise.
  static const _searchThreshold = 6;

  final _searchController = TextEditingController();
  late List<Deck> _results = widget.decks;

  bool get _showSearch => widget.decks.length > _searchThreshold;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    final normalized = query.trim().toLowerCase();
    setState(() {
      _results = normalized.isEmpty
          ? widget.decks
          : widget.decks
                .where((deck) => deck.name.toLowerCase().contains(normalized))
                .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasDecks = widget.decks.isNotEmpty;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              // The drag handle above already reserves the top gap.
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title ??
                        LocaleKeys.scanDestinationTitle.trParams({
                          'count': '${widget.wordCount}',
                        }),
                    style: AppTextStyles.heading2,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    widget.subtitle ?? LocaleKeys.scanDestinationSubtitle.tr,
                    style: AppTextStyles.body.copyWith(
                      color: context.colorInkMuted,
                    ),
                  ),
                  if (widget.allowNewDeck) ...[
                    const SizedBox(height: AppSpacing.lg),
                    _NewDeckOption(
                      onTap: () =>
                          Navigator.pop(context, const NewDeckDestination()),
                    ),
                  ],
                  if (hasDecks) ...[
                    const SizedBox(height: AppSpacing.lg),
                    if (widget.allowNewDeck) ...[
                      Text(
                        LocaleKeys.scanDestinationExistingHeader.tr,
                        style: AppTextStyles.caption.copyWith(
                          color: context.colorInkMuted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                    if (_showSearch) ...[
                      TextField(
                        controller: _searchController,
                        onChanged: _onSearchChanged,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.search_rounded, size: 20),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                  ],
                ],
              ),
            ),
            if (hasDecks)
              Flexible(
                child: _results.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Text(
                          '—',
                          style: AppTextStyles.body.copyWith(
                            color: context.colorInkMuted,
                          ),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          0,
                          AppSpacing.lg,
                          AppSpacing.lg,
                        ),
                        itemCount: _results.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (context, index) {
                          final deck = _results[index];
                          return _ExistingDeckOption(
                            deck: deck,
                            onTap: () => Navigator.pop(
                              context,
                              ExistingDeckDestination(deck),
                            ),
                          );
                        },
                      ),
              )
            else
              const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}

/// The "start a new deck" choice: filled in the accent, so it reads as the
/// primary action and stands apart from the quieter list of existing decks.
class _NewDeckOption extends StatelessWidget {
  const _NewDeckOption({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.accent,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              const Icon(Icons.add_rounded, color: Colors.white, size: 22),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      LocaleKeys.scanDestinationNewDeck.tr,
                      style: AppTextStyles.button.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      LocaleKeys.scanDestinationNewDeckHint.tr,
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One existing deck the batch can be added to, with its language pair and
/// current size so the user can tell similar decks apart.
class _ExistingDeckOption extends StatelessWidget {
  const _ExistingDeckOption({required this.deck, required this.onTap});

  final Deck deck;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final target =
        VocabularyLanguages.byCode(deck.targetLanguage)?.flag ??
        deck.targetLanguage;
    final source = VocabularyLanguages.byCode(deck.sourceLanguage)?.flag;
    final pair = source == null ? target : '$source → $target';

    return Material(
      color: context.colorSurface,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      deck.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: context.colorInk,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$pair · '
                      '${LocaleKeys.homeDeckCardCount.trParams({'count': '${deck.cardCount}'})}',
                      style: AppTextStyles.caption.copyWith(
                        color: context.colorInkMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.add_rounded, color: context.colorInkMuted, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
