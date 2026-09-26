import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../routes/app_routes.dart';
import '../services/auth/auth_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../utils/initials.dart';

/// The floating round buttons that live in a screen's top corners - the
/// account avatar on the app shell, the back button on the screens it
/// opens.
///
/// They share one set of numbers deliberately. A back button that lands a
/// few pixels off where the avatar was makes the whole screen look like it
/// shifted during the transition, and content that doesn't know how much
/// room they take ends up running underneath them - which is exactly what
/// happened to Home's streak pill.
class AppShellButton extends StatelessWidget {
  const AppShellButton({
    super.key,
    required this.child,
    required this.onTap,
    this.alignEnd = false,
    this.background,
    this.border,
  });

  static const double size = 40;
  static const double sideInset = AppSpacing.lg;

  /// Horizontal room a screen's own top-row content must leave so it never
  /// sits under one of these. Read it rather than guessing at 40-ish.
  static const double clearance = sideInset + size + AppSpacing.sm;

  /// Distance from the top of the screen, below the status bar or notch.
  static double top(BuildContext context) =>
      MediaQuery.of(context).padding.top + AppSpacing.sm;

  /// Vertical room to leave above a screen's own scrolling content.
  static double verticalClearance(BuildContext context) =>
      top(context) + size + AppSpacing.md;

  final Widget child;
  final VoidCallback onTap;

  /// Pins to the right instead of the left.
  final bool alignEnd;

  final Color? background;
  final Color? border;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top(context),
      left: alignEnd ? null : sideInset,
      right: alignEnd ? sideInset : null,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Container(
            height: size,
            width: size,
            decoration: BoxDecoration(
              color: background ?? AppColors.ink,
              shape: BoxShape.circle,
              border: border == null ? null : Border.all(color: border!),
            ),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}

/// The account avatar in the top-right of the app shell, over both tabs,
/// opening the account/settings screen that used to be the Profile tab.
class AppProfileButton extends StatelessWidget {
  const AppProfileButton({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Get.find<AuthService>().currentUser;
    final name = user?.fullName?.isNotEmpty == true ? user!.fullName : null;

    return AppShellButton(
      alignEnd: true,
      onTap: () => Get.toNamed(AppRoutes.profile),
      child: Text(
        initialsFor(name, user?.email),
        style: AppTextStyles.bodyMedium.copyWith(
          color: Colors.white,
          fontSize: 14,
        ),
      ),
    );
  }
}

/// The back button on screens the shell pushes, sized and placed to land
/// exactly where the avatar was so nothing appears to jump on the way in.
///
/// Surface-coloured rather than filled navy: it occupies the avatar's
/// geometry, but it shouldn't read as an avatar.
class AppShellBackButton extends StatelessWidget {
  const AppShellBackButton({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppShellButton(
      onTap: onTap ?? Get.back,
      background: context.colorSurface,
      border: context.colorBorder,
      child: Icon(Icons.arrow_back_rounded, size: 20, color: context.colorInk),
    );
  }
}
