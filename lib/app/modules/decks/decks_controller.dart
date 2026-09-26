import 'package:get/get.dart';

import '../../core/localization/locale_keys.dart';
import '../../core/services/deck/deck_repository.dart';
import '../../core/services/study/study_preferences_service.dart';
import '../../core/utils/app_snackbar.dart';
import '../../data/models/deck.dart';
import '../../data/models/flashcard.dart';
import '../../data/models/study_mode.dart';
import '../../routes/app_routes.dart';
import '../listen_session/listen_session_view.dart';
import '../study_session/study_session_view.dart';

/// The single owner of the signed-in user's decks list - Home reads from
/// this for its recent-decks preview rather than fetching its own copy.
///
/// It also owns *starting* a cross-deck session, because both Home and the
/// Decks tab offer one and neither should have its own copy of the rules.
class DecksController extends GetxController {
  /// Enough to cover any plausible backlog; the session itself caps how
  /// many of these actually get reviewed in one sitting.
  static const _dueQueueLimit = 200;

  /// How many cards an extra, ahead-of-schedule round serves. Small on
  /// purpose: the offer is "one more short round", tappable as often as
  /// the user likes, not a second full session they have to commit to.
  static const practiceRoundSize = 10;

  DeckRepository get _deckRepository => Get.find<DeckRepository>();

  StudyPreferencesService get _studyPreferences =>
      Get.find<StudyPreferencesService>();

  final isLoadingDecks = true.obs;
  final decks = <Deck>[].obs;

  /// Everything due right now across every deck, soonest first. Home
  /// offers this as a single review session so the user never has to
  /// work out which deck is worth opening.
  final dueCards = <Flashcard>[].obs;

  /// True while an extra round is being fetched, so the button can show
  /// it's working rather than looking dead on a slow connection.
  final isLoadingPractice = false.obs;

  /// How far into the upcoming queue extra practice has already walked.
  /// Advanced each round so tapping "10 more" repeatedly serves different
  /// cards instead of the same nearest ten; wraps when the queue runs out.
  int _practiceOffset = 0;

  int get dueCount => dueCards.length;

  bool get hasCards => decks.any((deck) => deck.cardCount > 0);

  /// Nothing is owed, but there are cards to practise ahead of schedule -
  /// the state that earns an extra round instead of a dead-end
  /// "come back tomorrow".
  bool get canPractice => dueCount == 0 && hasCards;

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

  /// Reviews everything due across every deck, in the user's preferred
  /// mode. The whole point is that the user doesn't pick a deck first -
  /// the scheduler already knows what's owed.
  Future<void> startDueSession() async {
    final cards = List.of(dueCards);
    if (cards.isEmpty) return;
    await _runSession(cards);
  }

  /// An extra round over cards that aren't due yet, for someone who has
  /// cleared the day's reviews and wants to keep going. Grades are shown
  /// and counted but not written back - see [StudySessionView.practiceOnly].
  Future<void> startPracticeRound() async {
    if (isLoadingPractice.value) return;
    isLoadingPractice.value = true;
    try {
      var cards = await _fetchPractice(_practiceOffset);
      // Walked off the end of the upcoming queue: start over from the
      // nearest cards rather than handing back an empty round.
      if (cards.isEmpty && _practiceOffset > 0) {
        _practiceOffset = 0;
        cards = await _fetchPractice(0);
      }
      if (cards.isEmpty) return;

      _practiceOffset += cards.length;
      await _runSession(cards, practiceOnly: true);
    } catch (_) {
      // Unlike refreshDecks, this ran because the user tapped something,
      // so failing quietly would just look like a dead button.
      AppSnackbar.error(LocaleKeys.commonSomethingWentWrong.tr);
    } finally {
      isLoadingPractice.value = false;
    }
  }

  Future<List<Flashcard>> _fetchPractice(int offset) => _deckRepository
      .listUpcomingFlashcards(limit: practiceRoundSize, offset: offset);

  Future<void> _runSession(
    List<Flashcard> cards, {
    bool practiceOnly = false,
  }) async {
    if (_studyPreferences.mode.value == StudyMode.listen) {
      await Get.to(() => ListenSessionView(flashcards: cards));
    } else {
      await Get.to(
        () => StudySessionView(
          flashcards: cards,
          practiceOnly: practiceOnly,
          // An extra round is exactly the cards it was handed, whatever
          // the daily goal says - the goal is already met by this point.
          cap: practiceOnly ? cards.length : null,
        ),
      );
    }

    await refreshDecks();
  }

  void goToDeck(Deck deck) =>
      Get.toNamed(AppRoutes.deckDetail, arguments: deck.id);
}
