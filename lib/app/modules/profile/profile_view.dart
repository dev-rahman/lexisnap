import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/app_snackbar.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/app_bottom_nav_bar.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/app_top_safe_area.dart';
import '../../routes/app_routes.dart';
import 'profile_controller.dart';

class ProfileView extends GetView<ProfileController> {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        top: false,
        child: AppTopSafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppBottomNavBar.clearance,
            ),
            child: Column(
              children: [
                Obx(() {
                  controller.refreshTrigger.value;
                  final user = controller.user;
                  final displayName = user?.fullName?.isNotEmpty == true
                      ? user!.fullName!
                      : 'Your account';
                  final initials = _initialsFor(displayName, user?.email);

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
                        onTap: () => _showEditNameSheet(
                          context,
                          controller,
                          displayName,
                        ),
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
                    _SettingsTile(
                      icon: Icons.notifications_outlined,
                      label: 'Notifications',
                      onTap: () => AppSnackbar.info(
                        'Notification settings are on the way.',
                      ),
                    ),
                    _SettingsTile(
                      icon: Icons.palette_outlined,
                      label: 'Appearance',
                      onTap: () => _showThemePicker(context, controller),
                    ),
                    _SettingsTile(
                      icon: Icons.help_outline_rounded,
                      label: 'Help & support',
                      onTap: () => Get.toNamed(AppRoutes.help),
                    ),
                    _SettingsTile(
                      icon: Icons.info_outline_rounded,
                      label: 'About LexiSnap',
                      onTap: () =>
                          AppSnackbar.info('About page is on the way.'),
                      showDivider: false,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Obx(
                  () => AppButton(
                    label: 'Sign out',
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
      ),
    );
  }

  String _initialsFor(String name, String? email) {
    if (name != 'Your account') {
      final parts = name.trim().split(RegExp(r'\s+'));
      final letters = parts.take(2).map((p) => p.isNotEmpty ? p[0] : '').join();
      if (letters.isNotEmpty) return letters.toUpperCase();
    }
    if (email != null && email.isNotEmpty) return email[0].toUpperCase();
    return '?';
  }
}

void _showEditNameSheet(
  BuildContext context,
  ProfileController controller,
  String currentName,
) {
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController(
    text: currentName == 'Your account' ? '' : currentName,
  );

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
              Text('Edit name', style: AppTextStyles.heading2),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'Full name',
                controller: nameController,
                textInputAction: TextInputAction.done,
                validator: (v) =>
                    Validators.required(v, message: 'Enter a name'),
              ),
              const SizedBox(height: AppSpacing.lg),
              Obx(
                () => AppButton(
                  label: 'Save',
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
              Text('Appearance', style: AppTextStyles.heading2),
              const SizedBox(height: AppSpacing.md),
              Obx(
                () => Column(
                  children: [
                    _ThemeOption(
                      label: 'System',
                      icon: Icons.brightness_auto_outlined,
                      isSelected:
                          controller.themeService.themeMode.value ==
                          ThemeMode.system,
                      onTap: () {
                        controller.themeService.setThemeMode(ThemeMode.system);
                        Get.back(); // Close the bottom sheet after selection
                      },
                    ),
                    _ThemeOption(
                      label: 'Light',
                      icon: Icons.light_mode_outlined,
                      isSelected:
                          controller.themeService.themeMode.value ==
                          ThemeMode.light,
                      onTap: () {
                        controller.themeService.setThemeMode(ThemeMode.light);
                        Get.back(); // Close the bottom sheet after selection
                      },
                    ),
                    _ThemeOption(
                      label: 'Dark',
                      icon: Icons.dark_mode_outlined,
                      isSelected:
                          controller.themeService.themeMode.value ==
                          ThemeMode.dark,
                      onTap: () {
                        controller.themeService.setThemeMode(ThemeMode.dark);
                        Get.back(); // Close the bottom sheet after selection
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

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
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
    this.showDivider = true,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
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
