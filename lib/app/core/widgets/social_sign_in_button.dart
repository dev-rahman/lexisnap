import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

enum SocialProvider { google, apple }

/// "Continue with Google" / "Continue with Apple" button used on the login
/// and sign-up screens. Styling follows each brand's guidelines (white
/// outlined button for Google, black filled button for Apple).
class SocialSignInButton extends StatelessWidget {
  const SocialSignInButton({
    super.key,
    required this.provider,
    required this.onPressed,
    this.isLoading = false,
  });

  final SocialProvider provider;
  final VoidCallback? onPressed;
  final bool isLoading;

  bool get _isApple => provider == SocialProvider.apple;

  @override
  Widget build(BuildContext context) {
    final disabled = isLoading || onPressed == null;
    final backgroundColor = _isApple ? Colors.black : Colors.white;
    final foregroundColor = _isApple ? Colors.white : AppColors.ink;

    return SizedBox(
      height: 52,
      child: OutlinedButton(
        onPressed: disabled ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          side: _isApple
              ? BorderSide.none
              : const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
        child: isLoading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _isApple
                      ? Icon(Icons.apple, size: 22, color: foregroundColor)
                      : SvgPicture.asset(
                          'assets/icons/google_logo.svg',
                          width: 20,
                          height: 20,
                        ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    _isApple ? 'Continue with Apple' : 'Continue with Google',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: foregroundColor,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
