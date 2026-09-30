import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../routes/app_routes.dart';
import '../services/auth/auth_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'app_avatar.dart';

/// The floating round buttons that live in a screen's top corners - the
/// account avatar on the app shell, the close button on the screens it
/// opens.
///
/// They share one set of numbers deliberately. A close button that lands a
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
///
/// Profile opens by growing out of this button (see
/// `AvatarRevealTransition`) while the avatar itself flies to the Profile
/// header as a Hero.
class AppProfileButton extends StatelessWidget {
  const AppProfileButton({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShellButton(
      alignEnd: true,
      onTap: () => Get.toNamed(AppRoutes.profile),
      // The avatar draws its own disc and ring.
      background: Colors.transparent,
      child: Hero(
        tag: AppAvatar.heroTag,
        transitionOnUserGestures: true,
        child: AppAvatar(user: Get.find<AuthService>().currentUser),
      ),
    );
  }
}

/// The close button on screens that open out of the shell's avatar, in the
/// avatar's exact spot: the screen opens from that corner, so it closes
/// from the same one, and nothing appears to jump on the way in or out.
///
/// Surface-coloured rather than filled navy: it occupies the avatar's
/// geometry, but it shouldn't read as an avatar.
class AppShellCloseButton extends StatelessWidget {
  const AppShellCloseButton({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppShellButton(
      alignEnd: true,
      onTap: onTap ?? Get.back,
      background: context.colorSurface,
      border: context.colorBorder,
      child: Icon(
        Icons.close_rounded,
        size: 20,
        color: context.colorInk,
        semanticLabel: MaterialLocalizations.of(context).closeButtonTooltip,
      ),
    );
  }
}
