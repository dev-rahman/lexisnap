import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/widgets/app_shell_buttons.dart';

/// Opens a page by fading it in while it scales up out of the shell's
/// avatar button, and closes it back into the button.
///
/// Pairs with the avatar's Hero, which flies to the page header at the
/// same time, so the page reads as opening out of the button that was
/// tapped rather than sliding in from the opposite edge.
///
/// Deliberately just a fade and a scale - the same two operations
/// Android's own page transitions use, and cheap for any phone's GPU. An
/// earlier version clipped the page to a growing circle and faded each
/// section in separately, which cost an anti-aliased full-screen clip and
/// several offscreen layers every frame: smooth enough on a flagship,
/// visibly heavy on anything less.
class AvatarRevealTransition extends CustomTransition {
  static const duration = Duration(milliseconds: 300);

  /// How small the page starts. Close to 1 on purpose: the avatar's flight
  /// carries the "comes from the corner" motion, the page only hints at it.
  static const _startScale = 0.92;

  @override
  Widget buildTransition(
    BuildContext context,
    Curve? curve,
    Alignment? alignment,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final screen = MediaQuery.sizeOf(context);
    final avatarCenter = FractionalOffset(
      (screen.width - AppShellButton.sideInset - AppShellButton.size / 2) /
          screen.width,
      (AppShellButton.top(context) + AppShellButton.size / 2) / screen.height,
    );
    final progress = animation.drive(CurveTween(curve: Curves.fastOutSlowIn));

    return FadeTransition(
      opacity: progress,
      child: ScaleTransition(
        scale: progress.drive(Tween(begin: _startScale, end: 1.0)),
        alignment: avatarCenter,
        child: child,
      ),
    );
  }
}
