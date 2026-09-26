import 'package:get/get.dart';

import 'dart:math';

import '../../core/services/auth/auth_service.dart';
import '../../core/services/streak/streak_service.dart';
import '../../core/services/study/study_preferences_service.dart';
import '../../data/models/app_user.dart';
import '../../routes/app_routes.dart';
import '../decks/decks_controller.dart';
import '../main/main_controller.dart';

class HomeController extends GetxController {
  /// Rough seconds per card, used only to promise the user a bounded
  /// session. Deliberately generous - under-promising a two-minute
  /// session that takes five is how you stop someone coming back.
  static const _secondsPerCard = 6;

  AuthService get _authService => Get.find<AuthService>();

  DecksController get decksController => Get.find<DecksController>();

  StreakService get streakService => Get.find<StreakService>();

  StudyPreferencesService get studyPreferences =>
      Get.find<StudyPreferencesService>();

  AppUser? get user => _authService.currentUser;

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

  /// Where the daily-goal ring should animate from. Held here rather than
  /// in widget state so a rebuild can't reset the replay mid-animation.
  final previousGoalProgress = 0.0.obs;

  /// Bumped after a session so the hero replays its numbers.
  final heroReplayToken = 0.obs;

  /// How many cards this session will actually serve, which is capped by
  /// the daily goal inside `StudySessionEngine`.
  int get reviewSessionSize =>
      min(decksController.dueCount, streakService.streak.value.dailyGoal);

  int get reviewMinutes =>
      max(1, (reviewSessionSize * _secondsPerCard / 60).ceil());

  void goToScan() => Get.toNamed(AppRoutes.scan);

  void goToDecksTab() => Get.find<MainController>().changeTab(1);

  /// Cards an extra round will serve, for the button's label.
  int get practiceRoundSize => DecksController.practiceRoundSize;

  /// Starts the day's session over everything due across every deck.
  /// [DecksController] owns the rules; Home only adds the bookkeeping the
  /// hero panel needs to replay its numbers afterwards.
  Future<void> startSession() =>
      _withHeroReplay(decksController.startDueSession);

  /// Another short round once the day's reviews are cleared, so
  /// "all caught up" isn't a locked door for someone who wants to keep
  /// going. Repeatable: each tap walks further into the upcoming queue.
  Future<void> startPractice() =>
      _withHeroReplay(decksController.startPracticeRound);

  Future<void> _withHeroReplay(Future<void> Function() start) async {
    previousGoalProgress.value = streakService.streak.value.goalProgress;
    await start();
    // Home is the screen the user lands back on, so it - not just the
    // session summary - should show what the session earned.
    heroReplayToken.value++;
  }
}
