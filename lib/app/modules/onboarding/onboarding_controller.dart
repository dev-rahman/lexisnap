import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/localization/locale_keys.dart';
import '../../core/services/onboarding/onboarding_service.dart';
import '../../routes/app_routes.dart';

class OnboardingPageData {
  const OnboardingPageData({
    required this.icon,
    required this.titleKey,
    required this.descriptionKey,
  });

  final IconData icon;

  /// [LocaleKeys] entries, not resolved text - resolve with `.tr` at the
  /// point of display so they stay correct across locale changes.
  final String titleKey;
  final String descriptionKey;
}

class OnboardingController extends GetxController {
  final pageController = PageController();
  final currentPage = 0.obs;

  static const pages = [
    OnboardingPageData(
      icon: Icons.document_scanner_outlined,
      titleKey: LocaleKeys.onboardingScanTitle,
      descriptionKey: LocaleKeys.onboardingScanBody,
    ),
    OnboardingPageData(
      icon: Icons.spellcheck_outlined,
      titleKey: LocaleKeys.onboardingWordsTitle,
      descriptionKey: LocaleKeys.onboardingWordsBody,
    ),
    OnboardingPageData(
      icon: Icons.auto_awesome_outlined,
      titleKey: LocaleKeys.onboardingSentencesTitle,
      descriptionKey: LocaleKeys.onboardingSentencesBody,
    ),
    OnboardingPageData(
      icon: Icons.style_outlined,
      titleKey: LocaleKeys.onboardingDeckTitle,
      descriptionKey: LocaleKeys.onboardingDeckBody,
    ),
  ];

  bool get isLastPage => currentPage.value == pages.length - 1;

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }

  void onPageChanged(int index) => currentPage.value = index;

  void next() {
    if (isLastPage) {
      complete();
      return;
    }
    pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> complete() async {
    await Get.find<OnboardingService>().markOnboardingSeen();
    Get.offAllNamed(AppRoutes.login);
  }
}
