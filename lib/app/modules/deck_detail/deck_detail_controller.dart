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
  Future<void> moveSelectedTo(Deck target) async {
    final ids = selectedCardIds.toList();
    final count = ids.length;
    if (ids.isEmpty) return;

    try {
      await _deckRepository.moveFlashcards(
        flashcardIds: ids,
        toDeckId: target.id,
      );
      exitSelection();
      await _load(silent: true);
      await Get.find<DecksController>().refreshDecks();
      AppSnackbar.success(
        LocaleKeys.cardsMovedSuccess.trParams({
          'count': '$count',
          'name': target.name,
        }),
      );
    } catch (_) {
      AppSnackbar.error(LocaleKeys.cardsMoveError.tr);
    }
  }

  /// Copies the current selection into [target], leaving the originals here.
  Future<void> copySelectedTo(Deck target) async {
    final ids = selectedCardIds.toList();
    final count = ids.length;
    if (ids.isEmpty) return;

    try {
      await _deckRepository.copyFlashcards(
        flashcardIds: ids,
        toDeckId: target.id,
      );
      exitSelection();
      await Get.find<DecksController>().refreshDecks();
      AppSnackbar.success(
        LocaleKeys.cardsCopiedSuccess.trParams({
          'count': '$count',
          'name': target.name,
        }),
      );
    } catch (_) {
      AppSnackbar.error(LocaleKeys.cardsCopyError.tr);
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
