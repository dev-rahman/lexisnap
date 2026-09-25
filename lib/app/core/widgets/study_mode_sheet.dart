import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../localization/locale_keys.dart';
import '../services/study/study_preferences_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../../data/models/study_mode.dart';

const studyModeIcons = {
  StudyMode.smart: Icons.auto_awesome_rounded,
  StudyMode.quiz: Icons.checklist_rounded,
  StudyMode.flip: Icons.swipe_rounded,
  StudyMode.listen: Icons.headphones_rounded,
};

const studyModeLabels = {
  StudyMode.smart: LocaleKeys.studyModeSmart,
  StudyMode.quiz: LocaleKeys.studyModeQuiz,
  StudyMode.flip: LocaleKeys.studyModeFlip,
  StudyMode.listen: LocaleKeys.deckListen,
};

const studyModeHints = {
  StudyMode.smart: LocaleKeys.studyModeSmartHint,
  StudyMode.quiz: LocaleKeys.studyModeQuizHint,
  StudyMode.flip: LocaleKeys.studyModeFlipHint,
  StudyMode.listen: LocaleKeys.studyModeListenHint,
};

/// Lets the learner choose how they're asked during a session.
///
/// One implementation shared by the Home hero's mode chip and the
/// Profile settings row, since the preference itself is global.
void showStudyModeSheet(BuildContext context) {
  final service = Get.find<StudyPreferencesService>();

  showModalBottomSheet(
    context: context,
    backgroundColor: context.colorPaper,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
    ),
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                LocaleKeys.studyModeTitle.tr,
                style: AppTextStyles.heading2,
              ),
              const SizedBox(height: AppSpacing.md),
              Obx(
                () => Column(
                  children: [
                    for (final mode in StudyMode.values)
                      _ModeOption(
                        mode: mode,
                        isSelected: service.mode.value == mode,
                        onTap: () {
                          service.setMode(mode);
                          Navigator.pop(sheetContext);
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _ModeOption extends StatelessWidget {
  const _ModeOption({
    required this.mode,
    required this.isSelected,
    required this.onTap,
  });

  final StudyMode mode;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? AppColors.accent : context.colorInk;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.sm,
            horizontal: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Icon(studyModeIcons[mode], size: 22, color: color),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      studyModeLabels[mode]!.tr,
                      style: AppTextStyles.bodyMedium.copyWith(color: color),
                    ),
                    Text(
                      studyModeHints[mode]!.tr,
                      style: AppTextStyles.caption.copyWith(
                        color: context.colorInkMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                const Icon(Icons.check_rounded, color: AppColors.accent),
            ],
          ),
        ),
      ),
    );
  }
}
