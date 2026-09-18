import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// "── or ──" row used to separate email auth from social sign-in options.
class OrDivider extends StatelessWidget {
  const OrDivider({super.key, this.label = 'or'});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.border)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ),
        const Expanded(child: Divider(color: AppColors.border)),
      ],
    );
  }
}
