import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/localization/locale_keys.dart';
import '../../core/services/notification/study_reminder_service.dart';
import '../../core/services/streak/streak_service.dart';
import '../../core/services/study/study_preferences_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/app_snackbar.dart';
import '../../core/widgets/app_avatar.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/confirm_sheet.dart';
import '../../core/widgets/app_settings_group.dart';
import '../../core/widgets/app_shell_buttons.dart';
import '../../core/widgets/study_mode_sheet.dart';
import '../../core/widgets/language_picker_sheet.dart';
import '../../routes/app_routes.dart';
import 'profile_controller.dart';

class ProfileView extends GetView<ProfileController> {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // No AppBar: this screen opens out of the floating avatar in the
      // shell's top-right corner, and an AppBar's icons sit higher than
      // that avatar did, so the whole screen looked like it shifted on the
      // way in. A floating close button on the shared geometry lands on
      // exactly the avatar's spot instead.
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppShellButton.verticalClearance(context),
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: Column(
                children: [
                  Obx(() {
                    final user = controller.user;
                    final actualName = user?.fullName?.isNotEmpty == true
                        ? user!.fullName!
                        : null;
                    final displayName =
                        actualName ?? LocaleKeys.profileYourAccount.tr;

                    return Column(
                      children: [
                        // Lands the avatar that flies over from the
                        // shell's corner button as this screen opens.
                        GestureDetector(
                          onTap: controller.openEditProfile,
                          child: SizedBox.square(
                            dimension: 76,
                            child: Hero(
                              tag: AppAvatar.heroTag,
                              transitionOnUserGestures: true,
                              child: AppAvatar(user: user),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        InkWell(
                          onTap: controller.openEditProfile,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: 2,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  displayName,
                                  style: AppTextStyles.heading2,
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                Icon(
                                  Icons.edit_outlined,
                                  size: 16,
                                  color: context.colorInkMuted,
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (user?.email != null) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            user!.email!,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                        const SizedBox(height: AppSpacing.md),
                        OutlinedButton.icon(
                          onPressed: controller.openEditProfile,
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          label: Text(LocaleKeys.profileEditProfile.tr),
                          // The theme's buttons are full-width 52pt blocks
                          // for a screen's main action; this is a small
                          // secondary one under the name.
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 38),
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                  const SizedBox(height: AppSpacing.lg * 1.5),
                  AppSettingsGroup(
                    children: [
                      Obx(() {
                        final reminder = Get.find<StudyReminderService>();
                        return AppSettingsTile(
                          icon: Icons.notifications_outlined,
                          label: LocaleKeys.reminderSettingsTitle.tr,
                          value: reminder.isEnabled.value
                              ? LocaleKeys.reminderEveryDayAt.trParams({
                                  'time': reminder.time.value.format(context),
                                })
                              : LocaleKeys.reminderOff.tr,
                          onTap: () => _showReminderSheet(context),
                        );
                      }),
                      Obx(() {
                        final mode =
                            Get.find<StudyPreferencesService>().mode.value;
                        return AppSettingsTile(
                          icon: studyModeIcons[mode]!,
                          label: LocaleKeys.studyModeTitle.tr,
                          value: studyModeLabels[mode]!.tr,
                          onTap: () => showStudyModeSheet(context),
                        );
                      }),
                      Obx(
                        () => AppSettingsTile(
                          icon: Icons.flag_outlined,
                          label: LocaleKeys.goalSettingsTitle.tr,
                          value: LocaleKeys.goalCardsPerDay.trParams({
                            'count':
                                '${Get.find<StreakService>().streak.value.dailyGoal}',
                          }),
                          onTap: () => _showGoalSheet(context),
                        ),
                      ),
                      AppSettingsTile(
                        icon: Icons.palette_outlined,
                        label: LocaleKeys.profileAppearance.tr,
                        onTap: () => _showThemePicker(context, controller),
                      ),
                      AppSettingsTile(
                        icon: Icons.language_outlined,
                        label: LocaleKeys.profileLanguage.tr,
                        onTap: () => showLanguagePickerSheet(context),
                      ),
                      AppSettingsTile(
                        icon: Icons.help_outline_rounded,
                        label: LocaleKeys.profileHelpSupport.tr,
                        onTap: () => Get.toNamed(AppRoutes.help),
                      ),
                      AppSettingsTile(
                        icon: Icons.info_outline_rounded,
                        label: LocaleKeys.profileAbout.tr,
                        onTap: () => AppSnackbar.info(
                          LocaleKeys.profileAboutComingSoon.tr,
                        ),
                        showDivider: false,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Obx(
                    () => AppButton(
                      label: LocaleKeys.profileSignOut.tr,
                      variant: AppButtonVariant.outlined,
                      color: AppColors.alert,
                      isLoading: controller.isSigningOut.value,
                      onPressed: () => _confirmSignOut(context, controller),
                    ),
                  ),
                ],
              ),
            ),
            const AppShellCloseButton(),
          ],
        ),
      ),
    );
  }
}

Future<void> _confirmSignOut(
  BuildContext context,
  ProfileController controller,
) async {
  final confirmed = await showConfirmSheet(
    context,
    icon: Icons.logout_rounded,
    title: LocaleKeys.signOutConfirmTitle.tr,
    body: LocaleKeys.signOutConfirmBody.tr,
    confirmLabel: LocaleKeys.profileSignOut.tr,
  );
  if (confirmed) await controller.signOut();
}

void _showThemePicker(BuildContext context, ProfileController controller) {
  showAppSheet(
    context,
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
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
              Text(
                LocaleKeys.profileAppearance.tr,
                style: AppTextStyles.heading2,
              ),
              const SizedBox(height: AppSpacing.md),
              Obx(
                () => Column(
                  children: [
                    _PickerOption(
                      label: LocaleKeys.themeSystem.tr,
                      icon: Icons.brightness_auto_outlined,
                      isSelected:
                          controller.themeService.themeMode.value ==
                          ThemeMode.system,
                      onTap: () {
                        controller.themeService.setThemeMode(ThemeMode.system);
                        Get.back();
                      },
                    ),
                    _PickerOption(
                      label: LocaleKeys.themeLight.tr,
                      icon: Icons.light_mode_outlined,
                      isSelected:
                          controller.themeService.themeMode.value ==
                          ThemeMode.light,
                      onTap: () {
                        controller.themeService.setThemeMode(ThemeMode.light);
                        Get.back();
                      },
                    ),
                    _PickerOption(
                      label: LocaleKeys.themeDark.tr,
                      icon: Icons.dark_mode_outlined,
                      isSelected:
                          controller.themeService.themeMode.value ==
                          ThemeMode.dark,
                      onTap: () {
                        controller.themeService.setThemeMode(ThemeMode.dark);
                        Get.back();
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

/// Turns the daily study reminder on or off and picks its time.
///
/// Opening a system permission prompt here rather than at first launch
/// means the OS dialog arrives right after the user has asked for
/// reminders, which is the only moment it makes sense to them.
void _showReminderSheet(BuildContext context) {
  final reminder = Get.find<StudyReminderService>();

  Future<void> setEnabled(bool enabled) async {
    if (!enabled) {
      await reminder.disable();
      return;
    }
    final granted = await reminder.enable();
    if (!granted) AppSnackbar.error(LocaleKeys.reminderPermissionDenied.tr);
  }

  showAppSheet(
    context,
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          // Top padding is 0: the drag handle above already
          // reserves a 48dp block, and adding lg on top of it
          // pushed every sheet title a third of the way down.
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Obx(
            () => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  LocaleKeys.reminderSettingsTitle.tr,
                  style: AppTextStyles.heading2,
                ),
                const SizedBox(height: AppSpacing.md),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  activeThumbColor: AppColors.accent,
                  value: reminder.isEnabled.value,
                  onChanged: setEnabled,
                  title: Text(
                    reminder.isEnabled.value
                        ? LocaleKeys.reminderEveryDayAt.trParams({
                            'time': reminder.time.value.format(sheetContext),
                          })
                        : LocaleKeys.reminderOff.tr,
                    style: AppTextStyles.bodyMedium,
                  ),
                ),
                if (reminder.isEnabled.value) ...[
                  const SizedBox(height: AppSpacing.sm),
                  AppButton(
                    variant: AppButtonVariant.outlined,
                    label: reminder.time.value.format(sheetContext),
                    icon: const Icon(Icons.schedule_rounded, size: 18),
                    onPressed: () async {
                      final picked = await showTimePicker(
                        context: sheetContext,
                        initialTime: reminder.time.value,
                      );
                      if (picked != null) await reminder.enable(at: picked);
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    },
  );
}

/// Sets how many cards a day counts as done - which also caps how many a
/// single session will serve up, so the goal and the session are the same
/// promise.
void _showGoalSheet(BuildContext context) {
  const options = [10, 20, 30, 50];
  final streakService = Get.find<StreakService>();

  showAppSheet(
    context,
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
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
              Text(
                LocaleKeys.goalSettingsTitle.tr,
                style: AppTextStyles.heading2,
              ),
              const SizedBox(height: AppSpacing.md),
              Obx(
                () => Column(
                  children: [
                    for (final option in options)
                      _PickerOption(
                        label: LocaleKeys.goalCardsPerDay.trParams({
                          'count': '$option',
                        }),
                        icon: Icons.flag_outlined,
                        isSelected:
                            streakService.streak.value.dailyGoal == option,
                        onTap: () {
                          streakService.setDailyGoal(option);
                          Get.back();
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

/// Shared row style for the Appearance bottom sheet: an icon, a label, and
/// a checkmark on the selected option.
class _PickerOption extends StatelessWidget {
  const _PickerOption({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
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
              Icon(
                icon,
                size: 22,
                color: isSelected ? AppColors.accent : context.colorInk,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isSelected ? AppColors.accent : context.colorInk,
                  ),
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
