import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/services/onboarding/onboarding_service.dart';
import '../../routes/app_routes.dart';

class OnboardingPageData {
  const OnboardingPageData({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;
}

class OnboardingController extends GetxController {
  final pageController = PageController();
  final currentPage = 0.obs;

  static const pages = [
    OnboardingPageData(
      icon: Icons.document_scanner_outlined,
      title: 'Scan anything',
      description:
          'Point your camera at a textbook page, a menu, a street sign - '
          'anything with text you want to learn from.',
    ),
    OnboardingPageData(
      icon: Icons.spellcheck_outlined,
      title: 'We find the new words',
      description:
          'LexiSnap picks out the vocabulary worth learning from your scan '
          'and lets you choose which ones to keep.',
    ),
    OnboardingPageData(
      icon: Icons.style_outlined,
      title: 'Your deck, ready to study',
      description:
          'Flashcards are built automatically, so you can start reviewing '
          'right away.',
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
