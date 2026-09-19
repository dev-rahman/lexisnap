import 'package:get/get.dart';

import 'auth/auth_service.dart';
import 'auth/supabase_auth_service.dart';
import 'locale/locale_service.dart';
import 'ocr/mlkit_text_recognition_service.dart';
import 'ocr/text_recognition_service.dart';
import 'onboarding/onboarding_service.dart';
import 'permission/permission_service.dart';
import 'theme/theme_service.dart';

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

    final themeService = ThemeService();
    await themeService.init();
    Get.put<ThemeService>(themeService, permanent: true);

    final localeService = LocaleService();
    await localeService.init();
    Get.put<LocaleService>(localeService, permanent: true);
  }
}
