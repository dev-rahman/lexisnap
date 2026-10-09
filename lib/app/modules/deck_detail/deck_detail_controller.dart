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

  final isLoading = true.obs;
  final deck = Rxn<Deck>();
  final flashcards = <Flashcard>[].obs;

  int get dueCount => flashcards.where((card) => card.isDue).length;

  /// Multi-select state for the card list. [isSelecting] turns the list into
  /// a picker (checkboxes, no swipe, tap toggles); [selectedCardIds] is what
  /// the move/copy/delete actions operate on.
  final isSelecting = false.obs;
  final selectedCardIds = <String>{}.obs;

  int get selectedCount => selectedCardIds.length;
  bool get hasSelection => selectedCardIds.isNotEmpty;
  bool isSelected(String cardId) => selectedCardIds.contains(cardId);

  bool get allSelected =>
      flashcards.isNotEmpty && selectedCardIds.length == flashcards.length;

  /// Decks a selection can move or copy into: everything the user owns that
  /// shares this deck's language pair, since a card's languages come from its
  /// deck - putting it in a mismatched deck would misrepresent it. The deck
  /// itself is excluded.
  List<Deck> get compatibleDecks {
    final current = deck.value;
    if (current == null) return const [];
    return Get.find<DecksController>().decks
        .where(
          (other) =>
              other.id != current.id &&
              other.sourceLanguage == current.sourceLanguage &&
              other.targetLanguage == current.targetLanguage,
        )
        .toList();
  }

  void enterSelection(String cardId) {
    isSelecting.value = true;
    selectedCardIds.add(cardId);
  }

  void toggleSelection(String cardId) {
    if (!selectedCardIds.remove(cardId)) selectedCardIds.add(cardId);
  }

  void toggleSelectAll() {
    if (allSelected) {
      selectedCardIds.clear();
    } else {
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

  @override
  void onInit() {
    super.onInit();
    _load();
  }

  /// Re-fetches the deck and its flashcards - used after a study session so
  /// due counts and cards reflect the just-recorded reviews.
  ///
  /// [silent] skips the loading spinner, for a refresh that follows a small
  /// change the user just made (editing or deleting a card) where the list
  /// is already on screen and a full-screen spinner would only flicker.
  Future<void> reload({bool silent = false}) => _load(silent: silent);

  Future<void> _load({bool silent = false}) async {
    if (!silent) isLoading.value = true;
    try {
      final (loadedDeck, loadedFlashcards) = await _deckRepository.getDeck(
        _deckId,
      );
      deck.value = loadedDeck;
      flashcards.assignAll(loadedFlashcards);
    } catch (_) {
      AppSnackbar.error(LocaleKeys.deckLoadError.tr);
    } finally {
      isLoading.value = false;
    }
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

      // Everything picked is already in the target: nothing to move. Stay in
      // selection so the user can aim at a different deck instead.
      if (part.freshIds.isEmpty) {
        AppSnackbar.info(
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
        AppSnackbar.info(
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
      AppSnackbar.success(
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
      AppSnackbar.success(
        part.skipped == 0
            ? LocaleKeys.deckMergedSuccess.trParams({'name': target.name})
            : LocaleKeys.deckMergedSkipped.trParams({
                'name': target.name,
                'skipped': '${part.skipped}',
              }),
      );
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
