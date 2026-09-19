import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// Replaces `SafeArea(top: true)` on screens with no app bar of their own.
///
/// Reads the device's actual top inset (status bar height on Android,
/// notch/Dynamic Island height on iOS - this is what gives correct native
/// clearance automatically, per device and per platform) and adds a
/// consistent bit of extra breathing room on top of it, so no screen has
/// to hand-tune its own top spacing or guess at a fixed pixel value.
///
/// Usage: put this inside `SafeArea(top: false, child: ...)` so the rest
/// (bottom/left/right) still gets normal safe-area handling, and this
/// widget owns the top:
/// ```dart
/// body: SafeArea(
///   top: false,
///   child: AppTopSafeArea(child: someScrollableContent),
/// ),
/// ```
class AppTopSafeArea extends StatelessWidget {
  const AppTopSafeArea({
    super.key,
    required this.child,
    this.extraSpacing = AppSpacing.lg,
  });

  final Widget child;
  final double extraSpacing;

  /// The height this widget reserves at the top: the device's real safe
  /// inset (status bar / notch / Dynamic Island) plus [extraSpacing]. Call
  /// this wherever you need that number directly instead of wrapping a
  /// child widget (e.g. to size something else to match).
  static double height(
    BuildContext context, {
    double extraSpacing = AppSpacing.lg,
  }) {
    return MediaQuery.of(context).padding.top + extraSpacing;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: height(context, extraSpacing: extraSpacing),
      ),
      child: child,
    );
  }
}
