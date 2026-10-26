import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../localization/locale_keys.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// "── or ──" row used to separate email auth from social sign-in options.
class OrDivider extends StatelessWidget {
  const OrDivider({super.key, this.label});

  final String? label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(color: context.colorBorder)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Text(
            label ?? LocaleKeys.commonOr.tr,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        Expanded(child: Divider(color: context.colorBorder)),
      ],
    );
  }
}
