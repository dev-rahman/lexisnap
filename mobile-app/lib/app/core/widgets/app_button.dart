import 'package:flutter/material.dart';

import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

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
    this.color,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final AppButtonVariant variant;
  final Widget? icon;

  /// Overrides the button's theme color (background for [AppButtonVariant.filled],
  /// foreground/border otherwise). Use sparingly - e.g. a destructive action
  /// like sign-out that shouldn't use the ordinary accent color.
  final Color? color;

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
                    : color ?? Theme.of(context).colorScheme.primary,
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
              // Labels are translated, so the longest locale decides
              // whether this fits. Flexible lets it wrap instead of
              // overflowing the button on a narrow phone.
              Flexible(
                child: Text(label, textAlign: TextAlign.center, maxLines: 2),
              ),
            ],
          );

    switch (variant) {
      case AppButtonVariant.filled:
        return ElevatedButton(
          onPressed: _disabled ? null : onPressed,
          style: color == null
              ? null
              : ElevatedButton.styleFrom(backgroundColor: color),
          child: child,
        );
      case AppButtonVariant.outlined:
        return OutlinedButton(
          onPressed: _disabled ? null : onPressed,
          style: color == null
              ? null
              : OutlinedButton.styleFrom(
                  foregroundColor: color,
                  side: BorderSide(color: color!),
                ),
          child: child,
        );
      case AppButtonVariant.text:
        return TextButton(
          onPressed: _disabled ? null : onPressed,
          // The same box as the filled and outlined variants, which get
          // theirs from the theme: full width, 52 tall, the same corners
          // and the same label size. A secondary action usually sits right
          // under a primary one, and a shorter, narrower button there
          // shows as a mismatched tap highlight and drifts to the left in
          // start-aligned sheets. Set here, not in the text button theme,
          // because plain TextButtons elsewhere are inline links
          // ("See all", "Forgot password?") that must stay compact.
          style: TextButton.styleFrom(
            foregroundColor: color,
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            textStyle: AppTextStyles.button,
          ),
          child: child,
        );
    }
  }
}
