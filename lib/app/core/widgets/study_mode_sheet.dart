import 'app_bottom_sheet.dart';

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

  showAppSheet(
    context,
    // A plain sheet is capped at 9/16 of the screen. Four modes with their
    // hints outgrow that on a small phone - in German most of all - and
    // the cap silently cut the last option off. Scroll-controlled, the
    // sheet is as tall as its options.
    isScrollControlled: true,
    builder: (sheetContext) {
      return SafeArea(
        child: SingleChildScrollView(
          // Top padding is 0: the drag handle above already
          // reserves a 48dp block, and adding lg on top of it
          // pushed every sheet title a third of the way down.
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(LocaleKeys.studyModeTitle.tr, style: AppTextStyles.heading2),
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

/// The current study mode as a small chip that opens [showStudyModeSheet],
/// shown wherever a session is started - the Home card and each deck - so
/// the mode can be changed right before studying rather than in Profile.
///
/// The mode is one app-wide preference, so changing it here changes it
/// everywhere.
class StudyModeChip extends StatelessWidget {
  const StudyModeChip({super.key, required this.mode, this.onDark = false});

  final StudyMode mode;

  /// On Home's navy panel the chip tints the panel rather than punching a
  /// paper-coloured hole in it; on a light card it's an outlined pill.
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final foreground = onDark
        ? Colors.white.withValues(alpha: 0.85)
        : context.colorInk;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      side: onDark ? BorderSide.none : BorderSide(color: context.colorBorder),
    );

    return Material(
      color: onDark ? Colors.white.withValues(alpha: 0.14) : context.colorPaper,
      shape: shape,
      child: InkWell(
        customBorder: shape,
        onTap: () => showStudyModeSheet(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(studyModeIcons[mode], size: 16, color: foreground),
              const SizedBox(width: AppSpacing.xs),
              Text(
                studyModeLabels[mode]!.tr,
                style: AppTextStyles.caption.copyWith(color: foreground),
              ),
              Icon(Icons.expand_more_rounded, size: 16, color: foreground),
            ],
          ),
        ),
      ),
    );
  }
}
