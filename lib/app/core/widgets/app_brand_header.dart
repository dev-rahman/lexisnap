import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../localization/locale_keys.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'app_logo.dart';

/// Left-aligned icon + wordmark + tagline lockup, used at the top of the
/// auth screens so every entry point into the app carries the brand.
class AppBrandHeader extends StatelessWidget {
  const AppBrandHeader({super.key, this.iconSize = 56});

  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        AppLogo(size: iconSize),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'Lexi',
                      style: AppTextStyles.heading2.copyWith(
                        color: context.colorInk,
                      ),
                    ),
                    TextSpan(
                      text: 'Snap',
                      style: AppTextStyles.heading2.copyWith(
                        color: AppColors.accent,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                LocaleKeys.brandTagline.tr,
                style: AppTextStyles.caption.copyWith(
                  color: context.colorInkMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
