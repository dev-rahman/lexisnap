import 'package:get/get.dart';

import 'auth/auth_service.dart';
import 'auth/supabase_auth_service.dart';
import 'deck/deck_repository.dart';
import 'deck/supabase_deck_repository.dart';
import 'locale/locale_service.dart';
import 'notification/study_reminder_service.dart';
import 'ocr/mlkit_text_recognition_service.dart';
import 'ocr/text_recognition_service.dart';
import 'onboarding/onboarding_service.dart';
import 'permission/permission_service.dart';
import 'speech/flutter_tts_service.dart';
import 'speech/text_to_speech_service.dart';
import 'streak/streak_service.dart';
import 'study/study_preferences_service.dart';
import 'theme/theme_service.dart';
import 'translation/supabase_edge_translation_service.dart';
import 'translation/translation_ai_service.dart';
import 'vocabulary/supabase_edge_vocabulary_service.dart';
import 'vocabulary/vocabulary_ai_service.dart';

/// Registers every app-wide service.
///
/// To switch backends later (e.g. Supabase -> Firebase), write a new
/// `AuthService` implementation and change ONLY the `Get.put` call below.
/// Every controller resolves `AuthService` through `Get.find`, so nothing
/// else in the app needs to change.
class ServiceLocator {
  ServiceLocator._();

  static Future<void> init() async {
    Get.put<AuthService>(SupabaseAuthService(), permanent: true);
    Get.put<OnboardingService>(OnboardingService(), permanent: true);
    Get.put<PermissionService>(PermissionService(), permanent: true);
    Get.put<TextRecognitionService>(
      MlKitTextRecognitionService(),
      permanent: true,
    );
    Get.put<VocabularyAiService>(
      SupabaseEdgeVocabularyService(),
      permanent: true,
    );
    Get.put<TranslationAiService>(
      SupabaseEdgeTranslationService(),
      permanent: true,
    );
    Get.put<DeckRepository>(SupabaseDeckRepository(), permanent: true);
    Get.put<TextToSpeechService>(FlutterTtsService(), permanent: true);

    final themeService = ThemeService();
    await themeService.init();
    Get.put<ThemeService>(themeService, permanent: true);

    final localeService = LocaleService();
    await localeService.init();
    Get.put<LocaleService>(localeService, permanent: true);

    Get.put<StreakService>(await StreakService().init(), permanent: true);
    Get.put<StudyPreferencesService>(
      await StudyPreferencesService().init(),
      permanent: true,
    );
    Get.put<StudyReminderService>(
      await StudyReminderService().init(),
      permanent: true,
    );
  }
}
