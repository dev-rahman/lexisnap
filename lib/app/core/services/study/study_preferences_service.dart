import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/models/study_mode.dart';

/// Remembers how the user likes to study, on-device.
///
/// Kept as one global preference rather than one per deck: a learner
/// tends to have a style, and asking them to re-pick it for every deck
/// would reintroduce exactly the per-session friction the mode picker
/// exists to remove.
class StudyPreferencesService extends GetxService {
  static const _modeKey = 'study_mode';

  final mode = StudyMode.smart.obs;

  Future<StudyPreferencesService> init() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_modeKey);

    mode.value = StudyMode.values.firstWhereOrNull(
          (value) => value.name == stored,
        ) ??
        StudyMode.smart;
    return this;
  }

  Future<void> setMode(StudyMode value) async {
    if (mode.value == value) return;
    mode.value = value;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_modeKey, value.name);
  }

  /// Back to the default mode, forgetting the stored choice. Used when the
  /// account is deleted.
  Future<void> reset() async {
    mode.value = StudyMode.smart;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_modeKey);
  }
}
