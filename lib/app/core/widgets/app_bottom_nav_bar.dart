import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// The app's bottom navigation, adapted per platform rather than reskinned
/// to look the same everywhere:
///  - iOS: a floating "liquid glass" pill (Home/Profile) with a Scan button
///    that floats above it, and scroll-aware minimize like iOS 26's tab bar.
///  - Android/other: Flutter's own stock Material 3 [NavigationBar], themed
///    to the app's palette but otherwise the platform-idiomatic component.
class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onHomeTap,
    required this.onProfileTap,
    required this.onScanTap,
    this.isMinimized = false,
  });

  static const double barHeight = 64;
  static const double bottomMargin = AppSpacing.sm;
  static const double scanButtonSize = 64;

  /// Reserve this much bottom space in scrollable tab content so it never
  /// sits behind the bar, on either platform.
  static const double clearance = bottomMargin + barHeight + AppSpacing.lg;

  final int currentIndex;
  final bool isMinimized;
  final VoidCallback onHomeTap;
  final VoidCallback onProfileTap;
  final VoidCallback onScanTap;

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return _LiquidTabBar(
        currentIndex: currentIndex,
        isMinimized: isMinimized,
        onHomeTap: onHomeTap,
        onProfileTap: onProfileTap,
        onScanTap: onScanTap,
      );
    }
    return _StockAndroidNavBar(
      currentIndex: currentIndex,
      onHomeTap: onHomeTap,
      onProfileTap: onProfileTap,
      onScanTap: onScanTap,
    );
  }
}

/// Android/other platforms: the real Material 3 NavigationBar, themed to
/// the app palette. Scan is a normal destination (no floating button) -
/// this is deliberately the platform's own component, not a custom design.
class _StockAndroidNavBar extends StatelessWidget {
  const _StockAndroidNavBar({
    required this.currentIndex,
    required this.onHomeTap,
    required this.onProfileTap,
    required this.onScanTap,
  });

  final int currentIndex;
  final VoidCallback onHomeTap;
  final VoidCallback onProfileTap;
  final VoidCallback onScanTap;

  // Material 3's default NavigationBar height (80) reads as oversized next
  // to the rest of the app; this is a more compact, still-comfortable
  // touch target.
  static const double _barContentHeight = 56;

  @override
  Widget build(BuildContext context) {
    // Map our 2 persistent tabs (Home/Profile) onto 3 visible
    // destinations, with Scan in the middle. Scan never stays "selected" -
    // tapping it pushes a route rather than switching tabs.
    final materialIndex = currentIndex == 0 ? 0 : 2;

    // NavigationBar already wraps itself in Material + SafeArea internally
    // (that's what it's designed for - the same as when it's placed via
    // Scaffold.bottomNavigationBar), so it handles the bottom gesture
    // inset correctly on its own: its Material background reaches the
    // true edge, and only its tappable content is padded above the
    // gesture handle. Our own outer SafeArea must skip both top and
    // bottom here, or it would consume the bottom inset *before*
    // NavigationBar sees it, pushing the whole bar (background included)
    // up and leaving a plain paper-colored gap below it - which is
    // exactly the bug being fixed.
    return SafeArea(
      top: false,
      bottom: false,
      child: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: context.colorPaper,
          indicatorColor: AppColors.accent.withValues(alpha: 0.16),
          surfaceTintColor: Colors.transparent,
          labelTextStyle: WidgetStateProperty.resolveWith(
            (states) => TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: states.contains(WidgetState.selected)
                  ? AppColors.accent
                  : context.colorInkMuted,
            ),
          ),
          iconTheme: WidgetStateProperty.resolveWith(
            (states) => IconThemeData(
              color: states.contains(WidgetState.selected)
                  ? AppColors.accent
                  : context.colorInkMuted,
            ),
          ),
        ),
        child: NavigationBar(
          height: _barContentHeight,
          selectedIndex: materialIndex,
          onDestinationSelected: (index) {
            switch (index) {
              case 0:
                onHomeTap();
              case 1:
                onScanTap();
              case 2:
                onProfileTap();
            }
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.document_scanner_outlined),
              selectedIcon: Icon(Icons.document_scanner_rounded),
              label: 'Scan',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

/// iOS: floating frosted-glass pill with a Scan button that overlaps its
/// top edge, and a scroll-aware "minimize" (shrinks and drops its labels
/// when the content scrolls down, expands back when scrolling up) in the
/// style of iOS 26's Liquid Glass tab bar.
class _LiquidTabBar extends StatelessWidget {
  const _LiquidTabBar({
    required this.currentIndex,
    required this.isMinimized,
    required this.onHomeTap,
    required this.onProfileTap,
    required this.onScanTap,
  });

  static const _minimizedBarHeight = 48.0;
  static const _minimizedScanButtonSize = 48.0;
  static const _animationDuration = Duration(milliseconds: 260);
  static const _animationCurve = Curves.easeOutCubic;

  final int currentIndex;
  final bool isMinimized;
  final VoidCallback onHomeTap;
  final VoidCallback onProfileTap;
  final VoidCallback onScanTap;

  double get _barHeight =>
      isMinimized ? _minimizedBarHeight : AppBottomNavBar.barHeight;

  double get _scanButtonSize =>
      isMinimized ? _minimizedScanButtonSize : AppBottomNavBar.scanButtonSize;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final barBottom = AppBottomNavBar.bottomMargin + bottomInset;

    return SizedBox(
      height:
          AppBottomNavBar.bottomMargin +
          AppBottomNavBar.barHeight +
          (AppBottomNavBar.scanButtonSize / 2) +
          bottomInset,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          AnimatedPositioned(
            duration: _animationDuration,
            curve: _animationCurve,
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            bottom: barBottom,
            height: _barHeight,
            child: _GlassPill(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _NavItem(
                    outlinedIcon: Icons.home_outlined,
                    filledIcon: Icons.home_rounded,
                    label: 'Home',
                    isActive: currentIndex == 0,
                    showLabel: !isMinimized,
                    onTap: onHomeTap,
                  ),
                  SizedBox(width: _scanButtonSize),
                  _NavItem(
                    outlinedIcon: Icons.person_outline_rounded,
                    filledIcon: Icons.person_rounded,
                    label: 'Profile',
                    isActive: currentIndex == 1,
                    showLabel: !isMinimized,
                    onTap: onProfileTap,
                  ),
                ],
              ),
            ),
          ),
          AnimatedPositioned(
            duration: _animationDuration,
            curve: _animationCurve,
            bottom: barBottom + _barHeight - (_scanButtonSize / 2),
            child: _ScanButton(size: _scanButtonSize, onTap: onScanTap),
          ),
        ],
      ),
    );
  }
}

class _GlassPill extends StatelessWidget {
  const _GlassPill({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          decoration: BoxDecoration(
            color: context.colorPaper.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: context.colorBorder.withValues(alpha: 0.6),
            ),
            boxShadow: [
              BoxShadow(
                color: context.colorInk.withValues(alpha: 0.08),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _ScanButton extends StatelessWidget {
  const _ScanButton({required this.size, required this.onTap});

  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: _LiquidTabBar._animationDuration,
        curve: _LiquidTabBar._animationCurve,
        height: size,
        width: size,
        decoration: BoxDecoration(
          color: AppColors.accent,
          shape: BoxShape.circle,
          border: Border.all(color: context.colorPaper, width: 3),
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Icon(
          Icons.document_scanner_rounded,
          color: Colors.white,
          size: size * 0.4,
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.outlinedIcon,
    required this.filledIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
    this.showLabel = true,
  });

  final IconData outlinedIcon;
  final IconData filledIcon;
  final String label;
  final bool isActive;
  final bool showLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.accent : context.colorInkMuted;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isActive ? filledIcon : outlinedIcon, color: color, size: 24),
          AnimatedSize(
            duration: _LiquidTabBar._animationDuration,
            curve: _LiquidTabBar._animationCurve,
            child: showLabel
                ? Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
