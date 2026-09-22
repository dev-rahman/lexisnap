import 'package:get/get.dart';

import '../../core/services/deck/deck_repository.dart';
import '../../data/models/deck.dart';
import '../../routes/app_routes.dart';

/// The single owner of the signed-in user's decks list - Home reads from
/// this for its recent-decks preview rather than fetching its own copy.
class DecksController extends GetxController {
  DeckRepository get _deckRepository => Get.find<DeckRepository>();

  final isLoadingDecks = true.obs;
  final decks = <Deck>[].obs;

  @override
  void onInit() {
    super.onInit();
    refreshDecks();
  }

  Future<void> refreshDecks() async {
    isLoadingDecks.value = true;
    try {
      decks.assignAll(await _deckRepository.listDecks());
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
