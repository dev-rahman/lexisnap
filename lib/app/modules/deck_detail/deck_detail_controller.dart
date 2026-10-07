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
}
