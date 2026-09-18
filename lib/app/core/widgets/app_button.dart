import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

enum AppButtonVariant { filled, outlined, text }

/// Reusable button used across the whole app. Handles its own loading
/// spinner and disabled state so screens never have to duplicate that
/// logic.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.variant = AppButtonVariant.filled,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final AppButtonVariant variant;
  final Widget? icon;

  bool get _disabled => isLoading || onPressed == null;

  @override
  Widget build(BuildContext context) {
    final child = isLoading
        ? SizedBox(
            height: 22,
            width: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              valueColor: AlwaysStoppedAnimation<Color>(
                variant == AppButtonVariant.filled
                    ? Colors.white
                    : Theme.of(context).colorScheme.primary,
              ),
            ),
          )
        : icon == null
            ? Text(label)
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  icon!,
                  const SizedBox(width: AppSpacing.sm),
                  Text(label),
                ],
              );

    switch (variant) {
      case AppButtonVariant.filled:
        return ElevatedButton(
          onPressed: _disabled ? null : onPressed,
          child: child,
        );
      case AppButtonVariant.outlined:
        return OutlinedButton(
          onPressed: _disabled ? null : onPressed,
          child: child,
        );
      case AppButtonVariant.text:
        return TextButton(
          onPressed: _disabled ? null : onPressed,
          child: child,
        );
    }
  }
}
