import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/app_snackbar.dart';
import '../../core/widgets/app_bottom_nav_bar.dart';
import '../../core/widgets/app_button.dart';
import 'profile_controller.dart';

class ProfileView extends GetView<ProfileController> {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final user = controller.user;
    final displayName = user?.fullName?.isNotEmpty == true ? user!.fullName! : 'Your account';
    final initials = _initialsFor(displayName, user?.email);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppBottomNavBar.clearance,
          ),
          child: Column(
            children: [
              Container(
                height: 76,
                width: 76,
                decoration: const BoxDecoration(color: AppColors.ink, shape: BoxShape.circle),
                child: Center(
                  child: Text(
                    initials,
                    style: AppTextStyles.heading1.copyWith(color: Colors.white, fontSize: 26),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(displayName, style: AppTextStyles.heading2),
              if (user?.email != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(user!.email!, style: Theme.of(context).textTheme.bodyMedium),
              ],
              const SizedBox(height: AppSpacing.lg * 1.5),
              _SettingsGroup(
                children: [
                  _SettingsTile(
                    icon: Icons.notifications_outlined,
                    label: 'Notifications',
                    onTap: () => AppSnackbar.info('Notification settings are on the way.'),
                  ),
                  _SettingsTile(
                    icon: Icons.palette_outlined,
                    label: 'Appearance',
                    onTap: () => AppSnackbar.info('Theme options are on the way.'),
                  ),
                  _SettingsTile(
                    icon: Icons.help_outline_rounded,
                    label: 'Help & support',
                    onTap: () => AppSnackbar.info('Help & support is on the way.'),
                  ),
                  _SettingsTile(
                    icon: Icons.info_outline_rounded,
                    label: 'About LexiSnap',
                    onTap: () => AppSnackbar.info('About page is on the way.'),
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

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
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
                  Icon(icon, size: 22, color: AppColors.ink),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: Text(label, style: AppTextStyles.bodyMedium)),
                  const Icon(Icons.chevron_right_rounded, color: AppColors.inkMuted),
                ],
              ),
            ),
          ),
        ),
        if (showDivider) const Divider(height: 1, color: AppColors.border, indent: AppSpacing.md, endIndent: AppSpacing.md),
      ],
    );
  }
}
