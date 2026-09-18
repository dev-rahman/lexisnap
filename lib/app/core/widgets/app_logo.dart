import 'package:flutter/material.dart';

/// The app icon mark, for use inside the app's own UI (auth screens,
/// onboarding). The source asset is a full-bleed square - platforms apply
/// their own corner mask for the home-screen icon, but in-app we round it
/// ourselves, proportionally, the same way the icon tile itself is rounded.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 64});

  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.22),
      child: Image.asset(
        'assets/icon/icon.png',
        width: size,
        height: size,
      ),
    );
  }
}
