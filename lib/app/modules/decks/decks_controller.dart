import 'package:flutter/widgets.dart';
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

  /// How many decks a page holds. The list is bounded (a per-user quota),
  /// but paging keeps the first paint cheap and the scroll lazy.
  static const _decksPageSize = 20;

  DeckRepository get _deckRepository => Get.find<DeckRepository>();

  StudyPreferencesService get _studyPreferences =>
      Get.find<StudyPreferencesService>();

  final isLoadingDecks = true.obs;
  final decks = <Deck>[].obs;

  /// True while a further page of decks is being appended, so the list can
  /// show a quiet spinner at its tail rather than jumping.
  final isLoadingMoreDecks = false.obs;

  /// False once a page comes back short, meaning there's nothing left to
  /// fetch - stops the scroll listener from firing pointless requests.
  bool _hasMoreDecks = true;

  /// Drives infinite scroll on the decks list. Owned here (not the view) so
  /// it survives rebuilds; disposed in [onClose].
  final scrollController = ScrollController();

  // Totals across every deck, from a server-side count rather than the
  // loaded page, so the stats row and "has any cards" stay right under
  // pagination.
  final _totalDeckCount = 0.obs;
  final _totalCardCount = 0.obs;

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

  /// The user's total number of decks, across every page.
  int get deckCount => _totalDeckCount.value;

  bool get hasCards => _totalCardCount.value > 0;

  /// Every card the user owns, across all decks.
  int get totalCardCount => _totalCardCount.value;

  /// Nothing is owed, but there are cards to practise ahead of schedule -
  /// the state that earns an extra round instead of a dead-end
  /// "come back tomorrow".
  bool get canPractice => dueCount == 0 && hasCards;

  @override
  void onInit() {
    super.onInit();
    scrollController.addListener(_onScroll);
    refreshDecks();
  }

  @override
  void onClose() {
    scrollController.dispose();
    super.onClose();
  }

  void _onScroll() {
    if (!scrollController.hasClients) return;
    final position = scrollController.position;
    // Kick off the next page a little before the very bottom, so the new
    // rows are usually ready by the time the user reaches them.
    if (position.pixels >= position.maxScrollExtent - 320) {
      loadMoreDecks();
    }
  }

  Future<void> refreshDecks() async {
    isLoadingDecks.value = true;
    try {
      final firstPage = await _deckRepository.listDecks(
        offset: 0,
        limit: _decksPageSize,
      );
      decks.assignAll(firstPage);
      _hasMoreDecks = firstPage.length == _decksPageSize;

      final totals = await _deckRepository.deckTotals();
      _totalDeckCount.value = totals.deckCount;
      _totalCardCount.value = totals.cardCount;

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

  /// Appends the next page of decks when the user scrolls near the end.
  /// Guards against overlapping fetches and stops once the backlog is
  /// exhausted.
  Future<void> loadMoreDecks() async {
    if (isLoadingMoreDecks.value || !_hasMoreDecks || isLoadingDecks.value) {
      return;
    }
    isLoadingMoreDecks.value = true;
    try {
      final next = await _deckRepository.listDecks(
        offset: decks.length,
        limit: _decksPageSize,
      );
      decks.addAll(next);
      _hasMoreDecks = next.length == _decksPageSize;
    } catch (_) {
      // Keep what's loaded; the next scroll past the threshold retries.
    } finally {
      isLoadingMoreDecks.value = false;
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
