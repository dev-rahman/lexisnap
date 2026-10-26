import 'package:shared_preferences/shared_preferences.dart';

/// Tracks whether the first-run walkthrough has been shown on this device.
/// Local device state only - unlike [AuthService], this has no reason to
/// be backend-swappable, so it isn't hidden behind an interface.
class OnboardingService {
  static const _seenKey = 'onboarding_seen';

  Future<bool> hasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_seenKey) ?? false;
  }

  Future<void> markOnboardingSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_seenKey, true);
  }
}
