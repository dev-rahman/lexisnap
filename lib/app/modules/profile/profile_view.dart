import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/localization/locale_keys.dart';
import '../../core/services/notification/study_reminder_service.dart';
import '../../core/services/streak/streak_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/app_snackbar.dart';
import '../../core/utils/initials.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/language_picker_sheet.dart';
import '../../routes/app_routes.dart';
import 'profile_controller.dart';

class ProfileView extends GetView<ProfileController> {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: Get.back,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Column(
            children: [
              Obx(() {
                controller.refreshTrigger.value;
                final user = controller.user;
                final actualName = user?.fullName?.isNotEmpty == true
                    ? user!.fullName!
                    : null;
                final displayName =
                    actualName ?? LocaleKeys.profileYourAccount.tr;
                final initials = initialsFor(actualName, user?.email);

                return Column(
                  children: [
                    Container(
                      height: 76,
                      width: 76,
                      decoration: const BoxDecoration(
                        color: AppColors.ink,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          initials,
                          style: AppTextStyles.heading1.copyWith(
                            color: Colors.white,
                            fontSize: 26,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    InkWell(
                      onTap: () =>
                          _showEditNameSheet(context, controller, actualName),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: 2,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(displayName, style: AppTextStyles.heading2),
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
                  ],
                );
              }),
              const SizedBox(height: AppSpacing.lg * 1.5),
              _SettingsGroup(
                children: [
                  Obx(() {
                    final reminder = Get.find<StudyReminderService>();
                    return _SettingsTile(
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
                  Obx(
                    () => _SettingsTile(
                      icon: Icons.flag_outlined,
                      label: LocaleKeys.goalSettingsTitle.tr,
                      value: LocaleKeys.goalCardsPerDay.trParams({
                        'count':
                            '${Get.find<StreakService>().streak.value.dailyGoal}',
                      }),
                      onTap: () => _showGoalSheet(context),
                    ),
                  ),
                  _SettingsTile(
                    icon: Icons.palette_outlined,
                    label: LocaleKeys.profileAppearance.tr,
                    onTap: () => _showThemePicker(context, controller),
                  ),
                  _SettingsTile(
                    icon: Icons.language_outlined,
                    label: LocaleKeys.profileLanguage.tr,
                    onTap: () => showLanguagePickerSheet(context),
                  ),
                  _SettingsTile(
                    icon: Icons.help_outline_rounded,
                    label: LocaleKeys.profileHelpSupport.tr,
                    onTap: () => Get.toNamed(AppRoutes.help),
                  ),
                  _SettingsTile(
                    icon: Icons.info_outline_rounded,
                    label: LocaleKeys.profileAbout.tr,
                    onTap: () =>
                        AppSnackbar.info(LocaleKeys.profileAboutComingSoon.tr),
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
                  onPressed: controller.signOut,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void _showEditNameSheet(
  BuildContext context,
  ProfileController controller,
  String? currentName,
) {
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController(text: currentName ?? '');

  showModalBottomSheet(
    context: context,
    backgroundColor: context.colorPaper,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
    ),
    builder: (sheetContext) {
      return Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg + MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                LocaleKeys.profileEditName.tr,
                style: AppTextStyles.heading2,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: LocaleKeys.commonFullName.tr,
                controller: nameController,
                textInputAction: TextInputAction.done,
                validator: (v) => Validators.required(
                  v,
                  message: LocaleKeys.validatorNameRequired.tr,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Obx(
                () => AppButton(
                  label: LocaleKeys.commonSave.tr,
                  isLoading: controller.isUpdatingName.value,
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      controller.updateName(nameController.text.trim());
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

void _showThemePicker(BuildContext context, ProfileController controller) {
  showModalBottomSheet(
    context: context,
    backgroundColor: context.colorPaper,
    shape: RoundedRectangleBorder(
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

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.colorSurface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(children: children),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.value,
    this.showDivider = true,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  /// Current setting, shown muted at the end of the row so the state is
  /// readable without opening the tile.
  final String? value;

  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.md,
              ),
              child: Row(
                children: [
                  Icon(icon, size: 22, color: context.colorInk),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: Text(label, style: AppTextStyles.bodyMedium)),
                  if (value != null) ...[
                    Flexible(
                      child: Text(
                        value!,
                        textAlign: TextAlign.end,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption.copyWith(
                          color: context.colorInkMuted,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                  ],
                  Icon(
                    Icons.chevron_right_rounded,
                    color: context.colorInkMuted,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            color: context.colorBorder,
            indent: AppSpacing.md,
            endIndent: AppSpacing.md,
          ),
      ],
    );
  }
}
