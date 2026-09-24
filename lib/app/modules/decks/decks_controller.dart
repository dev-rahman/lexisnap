import 'package:get/get.dart';

import '../../core/services/deck/deck_repository.dart';
import '../../data/models/deck.dart';
import '../../data/models/flashcard.dart';
import '../../routes/app_routes.dart';

/// The single owner of the signed-in user's decks list - Home reads from
/// this for its recent-decks preview rather than fetching its own copy.
class DecksController extends GetxController {
  /// Enough to cover any plausible backlog; the session itself caps how
  /// many of these actually get reviewed in one sitting.
  static const _dueQueueLimit = 200;

  DeckRepository get _deckRepository => Get.find<DeckRepository>();

  final isLoadingDecks = true.obs;
  final decks = <Deck>[].obs;

  /// Everything due right now across every deck, soonest first. Home
  /// offers this as a single review session so the user never has to
  /// work out which deck is worth opening.
  final dueCards = <Flashcard>[].obs;

  int get dueCount => dueCards.length;

  @override
  void onInit() {
    super.onInit();
    refreshDecks();
  }

  Future<void> refreshDecks() async {
    isLoadingDecks.value = true;
    try {
      decks.assignAll(await _deckRepository.listDecks());
      dueCards.assignAll(
        await _deckRepository.listDueFlashcards(limit: _dueQueueLimit),
      );
    } catch (_) {
      // Leave whatever decks were already loaded in place rather than
      // clearing them out on a transient network error.
    } finally {
      isLoadingDecks.value = false;
    }
  }

  void goToDeck(Deck deck) =>
      Get.toNamed(AppRoutes.deckDetail, arguments: deck.id);
}
