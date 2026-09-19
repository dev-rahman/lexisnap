import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/core/config/env.dart';
import 'app/core/localization/app_locales.dart';
import 'app/core/localization/app_translations.dart';
import 'app/core/services/locale/locale_service.dart';
import 'app/core/services/service_locator.dart';
import 'app/core/services/theme/theme_service.dart';
import 'app/core/theme/app_system_ui.dart';
import 'app/core/theme/app_theme.dart';
import 'app/routes/app_pages.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');

  await Supabase.initialize(
    url: Env.supabaseUrl,
    publishableKey: Env.supabasePublishableKey,
  );

  await ServiceLocator.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => GetMaterialApp(
        title: 'LexiSnap',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: Get.find<ThemeService>().themeMode.value,
        translations: AppTranslations(),
        locale: Get.find<LocaleService>().locale.value,
        fallbackLocale: AppLocales.fallback,
        initialRoute: AppPages.initial,
        getPages: AppPages.routes,
        builder: (context, child) {
          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: AppSystemUi.forBrightness(Theme.of(context).brightness),
            child: child!,
          );
        },
      ),
    );
  }
}
