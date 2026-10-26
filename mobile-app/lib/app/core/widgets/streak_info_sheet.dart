import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../localization/locale_keys.dart';
import '../services/streak/streak_rules.dart';
import '../services/streak/streak_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../utils/study_day.dart';
import 'app_bottom_sheet.dart';

/// Explains the streak, opened by tapping it.
///
/// A streak with rules nobody can see is one people stop trusting the first
/// time it does something they didn't expect - a freeze spent without
/// asking, a day that "didn't count", a count that didn't go up after a
/// frozen day. Every one of those is the rules working as designed, so the
/// answer is to show the rules, not to change them.
///
/// It opens on the user's own numbers rather than on prose: "you have one
/// freeze, two days until the next" is the question they actually tapped
/// to ask, and the rules underneath are the explanation of those numbers.
///
/// Every figure in the copy comes from [StreakRules] or the study-day
/// boundary, so the text can't quietly disagree with the code.
///
/// Capped at half the screen, with the content scrolling under a pinned
/// handle. A glance at your numbers shouldn't cost the whole screen, and a
/// capped sheet keeps its content clear of the bottom edge, where gesture
/// navigation claims every swipe that starts too low. A third was tried
/// first and looked cramped: it showed little more than the status card.
void showStreakInfoSheet(BuildContext context) {
  showAppSheet<void>(
    context,
    maxHeightFraction: 1 / 2,
    builder: (sheetContext) => const _StreakInfoSheet(),
  );
}

class _StreakInfoSheet extends StatefulWidget {
  const _StreakInfoSheet();

  @override
  State<_StreakInfoSheet> createState() => _StreakInfoSheetState();
}

class _StreakInfoSheetState extends State<_StreakInfoSheet> {
  // Owned here rather than borrowed from PrimaryScrollController, so the
  // scrollbar and the scroll view are guaranteed to be driving the same
  // position inside a modal route.
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final service = Get.find<StreakService>();
    final dayEnds = MaterialLocalizations.of(
      context,
    ).formatTimeOfDay(const TimeOfDay(hour: studyDayRolloverHour, minute: 0));

    // A scrollbar, because in a viewport this short the rules below the
    // fold would otherwise be easy to miss.
    return Scrollbar(
      controller: _scroll,
      child: SingleChildScrollView(
        controller: _scroll,
        // Top is 0: the drag handle above already reserves that gap.
        //
        // The bottom inset is scroll padding, not a SafeArea. A SafeArea
        // would shave the nav bar's height off an already small viewport;
        // as padding, the content uses the full height and only the last
        // rule is lifted clear of the bar once scrolled to the end.
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.lg + MediaQuery.paddingOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(LocaleKeys.streakInfoTitle.tr, style: AppTextStyles.heading2),
            const SizedBox(height: AppSpacing.md),
            Obx(
              () => _Status(
                streak: service.streak.value,
                daysToNextFreeze: service.daysToNextFreeze,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _Rule(
              hue: AppColors.amber,
              icon: Icons.local_fire_department_rounded,
              title: LocaleKeys.streakRuleDailyTitle.tr,
              body: LocaleKeys.streakRuleDailyBody.tr,
            ),
            _Rule(
              hue: AppColors.violet,
              icon: Icons.bedtime_rounded,
              title: LocaleKeys.streakRuleDayEndsTitle.trParams({
                'time': dayEnds,
              }),
              body: LocaleKeys.streakRuleDayEndsBody.tr,
            ),
            _Rule(
              hue: AppColors.sky,
              icon: Icons.ac_unit_rounded,
              title: LocaleKeys.streakRuleEarnTitle.tr,
              body: LocaleKeys.streakRuleEarnBody.trParams({
                'days': '${StreakRules.daysPerFreeze}',
                'max': '${StreakRules.maxFreezes}',
              }),
            ),
            _Rule(
              hue: AppColors.sky,
              icon: Icons.shield_rounded,
              title: LocaleKeys.streakRuleCoverTitle.tr,
              body: LocaleKeys.streakRuleCoverBody.tr,
            ),
            // Rose rather than the grading red: this is a consequence to
            // know about, not an error, and red is reserved for marking a
            // flashcard wrong.
            _Rule(
              hue: AppColors.rose,
              icon: Icons.restart_alt_rounded,
              title: LocaleKeys.streakRuleResetTitle.tr,
              body: LocaleKeys.streakRuleResetBody.tr,
              isLast: true,
            ),
          ],
        ),
      ),
    );
  }
}

/// The user's own numbers, above the rules that explain them.
class _Status extends StatelessWidget {
  const _Status({required this.streak, required this.daysToNextFreeze});

  final StudyStreak streak;
  final int? daysToNextFreeze;

  @override
  Widget build(BuildContext context) {
    final sky = AppColors.sky.resolve(context);
    final remaining = daysToNextFreeze;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.colorSurface,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _Figure(
                  hue: AppColors.amber,
                  icon: Icons.local_fire_department_rounded,
                  value: streak.current,
                  label: LocaleKeys.streakInfoCurrent.tr,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _Figure(
                  hue: AppColors.sky,
                  icon: Icons.ac_unit_rounded,
                  value: streak.freezes,
                  label: LocaleKeys.streakInfoFreezes.tr,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (remaining == null)
            Text(
              LocaleKeys.streakInfoFreezesFull.trParams({
                'count': '${StreakRules.maxFreezes}',
              }),
              style: AppTextStyles.caption.copyWith(
                color: sky,
                fontWeight: FontWeight.w600,
              ),
            )
          else ...[
            // Progress through the current seven-day stretch - the rule
            // "every 7 days earns one", drawn instead of stated.
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value:
                    (streak.current % StreakRules.daysPerFreeze) /
                    StreakRules.daysPerFreeze,
                minHeight: 6,
                backgroundColor: context.colorBorder,
                valueColor: AlwaysStoppedAnimation(sky),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              remaining == 1
                  ? LocaleKeys.streakFreezeNextOne.tr
                  : LocaleKeys.streakFreezeNext.trParams({
                      'count': '$remaining',
                    }),
              style: AppTextStyles.caption.copyWith(
                color: context.colorInkMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure({
    required this.hue,
    required this.icon,
    required this.value,
    required this.label,
  });

  final AppHue hue;
  final IconData icon;
  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final color = hue.resolve(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: hue.tint(context),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$value',
                  style: AppTextStyles.display.copyWith(
                    color: context.colorInk,
                    fontSize: 22,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.label.copyWith(
                    color: context.colorInkMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One rule: a hued icon, a short title that states it, and one or two
/// lines of detail. Titles are written to be skimmed on their own, so a
/// user who reads only the bold lines still comes away with the model.
class _Rule extends StatelessWidget {
  const _Rule({
    required this.hue,
    required this.icon,
    required this.title,
    required this.body,
    this.isLast = false,
  });

  final AppHue hue;
  final IconData icon;
  final String title;
  final String body;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 36,
            width: 36,
            decoration: BoxDecoration(
              color: hue.tint(context),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(icon, color: hue.resolve(context), size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: context.colorInk,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: AppTextStyles.caption.copyWith(
                    color: context.colorInkMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
