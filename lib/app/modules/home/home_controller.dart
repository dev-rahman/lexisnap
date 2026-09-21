import 'package:get/get.dart';

import '../../core/services/auth/auth_service.dart';
import '../../core/services/deck/deck_repository.dart';
import '../../data/models/app_user.dart';
import '../../data/models/deck.dart';
import '../../routes/app_routes.dart';

class HomeController extends GetxController {
  AuthService get _authService => Get.find<AuthService>();

  DeckRepository get _deckRepository => Get.find<DeckRepository>();

  AppUser? get user => _authService.currentUser;

  final isLoadingDecks = true.obs;
  final decks = <Deck>[].obs;

  /// The user's first name, if we have one to greet them with. `null`
  /// means the view should fall back to a generic greeting instead of
  /// interpolating a name into the translated greeting string.
  String? get firstName {
    final user = this.user;
    if (user?.fullName?.isNotEmpty == true) {
      return user!.fullName!.split(' ').first;
    }
    return user?.email?.split('@').first;
  }

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

  void goToScan() => Get.toNamed(AppRoutes.scan);

  void goToDeck(Deck deck) =>
      Get.toNamed(AppRoutes.deckDetail, arguments: deck.id);
}
