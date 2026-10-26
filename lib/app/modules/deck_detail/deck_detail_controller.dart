import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../core/localization/locale_keys.dart';
import '../../core/services/deck/deck_repository.dart';
import '../../core/utils/app_snackbar.dart';
import '../../data/models/deck.dart';
import '../../data/models/flashcard.dart';
import '../decks/decks_controller.dart';

class DeckDetailController extends GetxController {
  DeckRepository get _deckRepository => Get.find<DeckRepository>();

  late final String _deckId = Get.arguments as String;

  /// How many cards a page holds. Browsing stays light even for a deck near
  /// the per-deck quota; whole-deck actions load the rest on demand.
  static const _cardsPageSize = 20;

  final isLoading = true.obs;
  final deck = Rxn<Deck>();

  /// The cards loaded so far - one page at first, growing as the user scrolls
  /// (and pulled in full by [_ensureAllCardsLoaded] for whole-deck actions).
  final flashcards = <Flashcard>[].obs;

  /// True while a further page is being appended, for the tail spinner.
  final isLoadingMoreCards = false.obs;

  /// False once a short page comes back - nothing left to fetch.
  bool _hasMoreCards = true;

  /// Drives infinite scroll on the card list; disposed in [onClose].
  final scrollController = ScrollController();

  /// The deck's due count, counted server-side so the header is right even
  /// when only a page of cards is in memory.
  final _dueCount = 0.obs;

  int get dueCount => _dueCount.value;

  /// Multi-select state for the card list. [isSelecting] turns the list into
  /// a picker (checkboxes, no swipe, tap toggles); [selectedCardIds] is what
  /// the move/copy/delete actions operate on.
  final isSelecting = false.obs;
  final selectedCardIds = <String>{}.obs;

  int get selectedCount => selectedCardIds.length;
  bool get hasSelection => selectedCardIds.isNotEmpty;
  bool isSelected(String cardId) => selectedCardIds.contains(cardId);

  /// The deck's total card count (from its metadata), so "select all" and the
  /// toggle label are judged against the whole deck, not just the loaded page.
  int get _totalCards => deck.value?.cardCount ?? flashcards.length;

  bool get allSelected =>
      _totalCards > 0 && selectedCardIds.length == _totalCards;

  /// Decks a selection can move or copy into: everything the user owns that
  /// shares this deck's language pair, since a card's languages come from its
  /// deck - putting it in a mismatched deck would misrepresent it. The deck
  /// itself is excluded. Resolved server-side so it's complete even when the
  /// decks list is only partly paged in.
  Future<List<Deck>> fetchCompatibleDecks() async {
    final current = deck.value;
    if (current == null) return const [];
    final matches = await _deckRepository.listDecksByLanguagePair(
      sourceLanguage: current.sourceLanguage,
      targetLanguage: current.targetLanguage,
    );
    return matches.where((other) => other.id != current.id).toList();
  }

  void enterSelection(String cardId) {
    isSelecting.value = true;
    selectedCardIds.add(cardId);
  }

  void toggleSelection(String cardId) {
    if (!selectedCardIds.remove(cardId)) selectedCardIds.add(cardId);
  }

  Future<void> toggleSelectAll() async {
    if (allSelected) {
      selectedCardIds.clear();
    } else {
      // "Select all" means the whole deck, so pull in any cards not yet
      // paged in before selecting - otherwise it would quietly select only
      // what happens to be on screen.
      await _ensureAllCardsLoaded();
      selectedCardIds.assignAll(flashcards.map((card) => card.id));
    }
  }

  void exitSelection() {
    isSelecting.value = false;
    selectedCardIds.clear();
  }

  List<Flashcard> _selectedCards() =>
      flashcards.where((card) => selectedCardIds.contains(card.id)).toList();

  /// Splits [cards] into the ids that can go into [targetDeckId] without
  /// making a within-deck duplicate, and how many were skipped. A word
  /// already in the target - or repeated within [cards] itself - is skipped,
  /// so a deck never holds the same word twice. The same word in a *different*
  /// deck is left alone; only duplicates inside one deck are blocked.
  Future<({List<String> freshIds, int skipped})> _dedupeAgainst(
    String targetDeckId,
    List<Flashcard> cards,
  ) async {
    final seen = await _deckRepository.wordsInDeck(targetDeckId);
    final freshIds = <String>[];
    var skipped = 0;
    for (final card in cards) {
      // Set.add returns false when the word was already present, which folds
      // the target's words and earlier cards in this batch into one check.
      if (seen.add(card.word.toLowerCase())) {
        freshIds.add(card.id);
      } else {
        skipped++;
      }
    }
    return (freshIds: freshIds, skipped: skipped);
  }

  /// How many of the currently selected words already exist in [target]. Lets
  /// the destination picker flag a deck whose words are all already there
  /// before it closes, instead of closing and reporting nothing happened.
  Future<int> duplicatesIn(Deck target) async {
    final part = await _dedupeAgainst(target.id, _selectedCards());
    return part.skipped;
  }

  @override
  void onInit() {
    super.onInit();
    scrollController.addListener(_onScroll);
    _load();
  }

  @override
  void onClose() {
    scrollController.dispose();
    super.onClose();
  }

  void _onScroll() {
    if (!scrollController.hasClients) return;
    final position = scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 320) {
      loadMoreCards();
    }
  }

  /// Re-fetches the deck and its first page of flashcards - used after a
  /// study session so due counts and cards reflect the just-recorded reviews.
  ///
  /// [silent] skips the loading spinner, for a refresh that follows a small
  /// change the user just made (editing or deleting a card) where the list
  /// is already on screen and a full-screen spinner would only flicker.
  Future<void> reload({bool silent = false}) => _load(silent: silent);

  Future<void> _load({bool silent = false}) async {
    if (!silent) isLoading.value = true;
    try {
      final meta = await _deckRepository.getDeckMeta(_deckId);
      deck.value = meta;

      final firstPage = await _deckRepository.listDeckCards(
        _deckId,
        sourceLanguage: meta.sourceLanguage,
        targetLanguage: meta.targetLanguage,
        offset: 0,
        limit: _cardsPageSize,
      );
      flashcards.assignAll(firstPage);
      _hasMoreCards = firstPage.length == _cardsPageSize;

      _dueCount.value = await _deckRepository.deckDueCount(_deckId);
    } catch (_) {
      AppSnackbar.error(LocaleKeys.deckLoadError.tr);
    } finally {
      isLoading.value = false;
    }
  }

  /// Appends the next page of cards as the user scrolls near the end.
  Future<void> loadMoreCards() async {
    if (isLoadingMoreCards.value || !_hasMoreCards || isLoading.value) return;
    final current = deck.value;
    if (current == null) return;

    isLoadingMoreCards.value = true;
    try {
      final next = await _deckRepository.listDeckCards(
        _deckId,
        sourceLanguage: current.sourceLanguage,
        targetLanguage: current.targetLanguage,
        offset: flashcards.length,
        limit: _cardsPageSize,
      );
      flashcards.addAll(next);
      _hasMoreCards = next.length == _cardsPageSize;
    } catch (_) {
      // Keep what's loaded; the next scroll past the threshold retries.
    } finally {
      isLoadingMoreCards.value = false;
    }
  }

  /// Pulls every remaining card into [flashcards] - for whole-deck actions
  /// (studying, merging, select-all) that need the full set, not just a page.
  Future<void> _ensureAllCardsLoaded() async {
    if (!_hasMoreCards) return;
    final (_, all) = await _deckRepository.getDeck(_deckId);
    flashcards.assignAll(all);
    _hasMoreCards = false;
  }

  /// The deck's full card list, loading any not-yet-paged cards first. For
  /// starting a study or listen session over the whole deck.
  Future<List<Flashcard>> allCards() async {
    await _ensureAllCardsLoaded();
    return flashcards.toList();
  }

  Future<void> renameDeck(String newName) async {
    final current = deck.value;
    if (current == null || newName.isEmpty) return;

    try {
      await _deckRepository.renameDeck(_deckId, newName);
      deck.value = Deck(
        id: current.id,
        name: newName,
        sourceLanguage: current.sourceLanguage,
        targetLanguage: current.targetLanguage,
        cardCount: current.cardCount,
        createdAt: current.createdAt,
        notes: current.notes,
      );
      await Get.find<DecksController>().refreshDecks();
    } catch (_) {
      AppSnackbar.error(LocaleKeys.deckRenameError.tr);
    }
  }

  Future<void> deleteDeck() async {
    try {
      await _deckRepository.deleteDeck(_deckId);
      await Get.find<DecksController>().refreshDecks();
      Get.back();
      AppSnackbar.success(LocaleKeys.deckDeletedSuccess.tr);
    } catch (_) {
      AppSnackbar.error(LocaleKeys.deckDeleteError.tr);
    }
  }

  /// Deletes a single [card] from this deck, for swipe-to-delete on the
  /// card list. Returns whether it succeeded, so the row can snap back
  /// into place when the delete fails rather than vanishing.
  ///
  /// The caller removes the row itself once the swipe is confirmed (see the
  /// `Dismissible` in the view); here we only correct the deck's own count
  /// and the decks list, and report the outcome.
  Future<bool> deleteCard(Flashcard card) async {
    final current = deck.value;
    try {
      await _deckRepository.deleteFlashcard(card.id);
      if (current != null) {
        deck.value = Deck(
          id: current.id,
          name: current.name,
          sourceLanguage: current.sourceLanguage,
          targetLanguage: current.targetLanguage,
          cardCount: current.cardCount > 0 ? current.cardCount - 1 : 0,
          createdAt: current.createdAt,
          notes: current.notes,
        );
      }
      await Get.find<DecksController>().refreshDecks();
      AppSnackbar.success(LocaleKeys.cardDeletedSuccess.tr);
      return true;
    } catch (_) {
      AppSnackbar.error(LocaleKeys.cardDeleteError.tr);
      return false;
    }
  }

  /// Moves the current selection into [target], then leaves selection mode
  /// and refreshes so both decks' counts are current.
  Future<void> moveSelectedTo(Deck target) =>
      _moveSelected(() async => target.id, target.name);

  /// Moves the current selection into a new deck named [name], created with
  /// this deck's language pair so the cards stay valid.
  Future<void> moveSelectedToNewDeck(String name) =>
      _moveSelected(() => _createDeckLikeCurrent(name), name);

  /// Copies the current selection into [target], leaving the originals here.
  Future<void> copySelectedTo(Deck target) =>
      _copySelected(() async => target.id, target.name);

  /// Copies the current selection into a new deck named [name].
  Future<void> copySelectedToNewDeck(String name) =>
      _copySelected(() => _createDeckLikeCurrent(name), name);

  Future<void> _moveSelected(
    Future<String> Function() resolveTargetId,
    String targetName,
  ) async {
    final selected = _selectedCards();
    if (selected.isEmpty) return;

    try {
      final targetId = await resolveTargetId();
      final part = await _dedupeAgainst(targetId, selected);

      // Safety net: the picker already warns before closing on an all-present
      // deck, so this is only reached on a race. Stay in selection.
      if (part.freshIds.isEmpty) {
        AppSnackbar.warning(
          LocaleKeys.cardsAllPresent.trParams({'name': targetName}),
        );
        return;
      }

      await _deckRepository.moveFlashcards(
        flashcardIds: part.freshIds,
        toDeckId: targetId,
      );
      exitSelection();
      await _load(silent: true);
      await Get.find<DecksController>().refreshDecks();
      _announceAdded(
        added: part.freshIds.length,
        skipped: part.skipped,
        name: targetName,
        movedNotCopied: true,
      );
    } catch (_) {
      AppSnackbar.error(LocaleKeys.cardsMoveError.tr);
    }
  }

  Future<void> _copySelected(
    Future<String> Function() resolveTargetId,
    String targetName,
  ) async {
    final selected = _selectedCards();
    if (selected.isEmpty) return;

    try {
      final targetId = await resolveTargetId();
      final part = await _dedupeAgainst(targetId, selected);

      if (part.freshIds.isEmpty) {
        AppSnackbar.warning(
          LocaleKeys.cardsAllPresent.trParams({'name': targetName}),
        );
        return;
      }

      await _deckRepository.copyFlashcards(
        flashcardIds: part.freshIds,
        toDeckId: targetId,
      );
      exitSelection();
      await Get.find<DecksController>().refreshDecks();
      _announceAdded(
        added: part.freshIds.length,
        skipped: part.skipped,
        name: targetName,
        movedNotCopied: false,
      );
    } catch (_) {
      AppSnackbar.error(LocaleKeys.cardsCopyError.tr);
    }
  }

  /// Success message for a move or copy, noting any cards skipped as
  /// duplicates of words already in the target.
  void _announceAdded({
    required int added,
    required int skipped,
    required String name,
    required bool movedNotCopied,
  }) {
    if (skipped == 0) {
      AppSnackbar.success(
        (movedNotCopied
                ? LocaleKeys.cardsMovedSuccess
                : LocaleKeys.cardsCopiedSuccess)
            .trParams({'count': '$added', 'name': name}),
      );
    } else {
      // Some were skipped as duplicates: a caution, not a clean success.
      AppSnackbar.warning(
        (movedNotCopied
                ? LocaleKeys.cardsMovedSkipped
                : LocaleKeys.cardsCopiedSkipped)
            .trParams({'count': '$added', 'skipped': '$skipped', 'name': name}),
      );
    }
  }

  /// Creates an empty deck carrying this deck's language pair, for a move or
  /// copy into a brand-new deck.
  Future<String> _createDeckLikeCurrent(String name) {
    final current = deck.value!;
    return _deckRepository.createEmptyDeck(
      name: name,
      sourceLanguage: current.sourceLanguage,
      targetLanguage: current.targetLanguage,
    );
  }

  /// Merges this whole deck into [target]: every card whose word is not
  /// already there moves across, words the target already has are dropped as
  /// duplicates, then this deck is deleted and we leave its (now gone) detail.
  Future<void> mergeIntoDeck(Deck target) async {
    try {
      // Merge moves the whole deck across, so every card has to be in memory,
      // not just the page the user scrolled to.
      await _ensureAllCardsLoaded();
      final part = await _dedupeAgainst(target.id, flashcards.toList());
      if (part.freshIds.isNotEmpty) {
        await _deckRepository.moveFlashcards(
          flashcardIds: part.freshIds,
          toDeckId: target.id,
        );
      }
      // Deleting this deck cascades away the cards that were skipped as
      // duplicates - the target already has those words, so nothing is lost.
      await _deckRepository.deleteDeck(_deckId);
      await Get.find<DecksController>().refreshDecks();
      Get.back();
      if (part.skipped == 0) {
        AppSnackbar.success(
          LocaleKeys.deckMergedSuccess.trParams({'name': target.name}),
        );
      } else {
        AppSnackbar.warning(
          LocaleKeys.deckMergedSkipped.trParams({
            'name': target.name,
            'skipped': '${part.skipped}',
          }),
        );
      }
    } catch (_) {
      AppSnackbar.error(LocaleKeys.deckMergeError.tr);
    }
  }

  /// Deletes the current selection from this deck.
  Future<void> deleteSelected() async {
    final ids = selectedCardIds.toList();
    final count = ids.length;
    if (ids.isEmpty) return;

    try {
      await _deckRepository.deleteFlashcards(ids);
      exitSelection();
      await _load(silent: true);
      await Get.find<DecksController>().refreshDecks();
      AppSnackbar.success(
        LocaleKeys.cardsDeletedSuccess.trParams({'count': '$count'}),
      );
    } catch (_) {
      AppSnackbar.error(LocaleKeys.cardsDeleteError.tr);
    }
  }
}
