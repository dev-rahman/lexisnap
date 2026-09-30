import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// A rounded surface card holding a list of [AppSettingsTile]s - the
/// grouped rows on Profile and Edit profile.
class AppSettingsGroup extends StatelessWidget {
  const AppSettingsGroup({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.colorSurface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(children: children),
    );
  }
}

class AppSettingsTile extends StatelessWidget {
  const AppSettingsTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.value,
    this.color,
    this.showDivider = true,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  /// Current setting, shown muted at the end of the row so the state is
  /// readable without opening the tile.
  final String? value;

  /// Tints the icon and label - [AppColors.alert] for a destructive row.
  final Color? color;

  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final foreground = color ?? context.colorInk;

    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.md,
              ),
              child: Row(
                children: [
                  Icon(icon, size: 22, color: foreground),
                  const SizedBox(width: AppSpacing.md),
                  // Label and value share one Expanded row rather than
                  // being two flex children of the outer one. As siblings
                  // they split the free space by flex factor, so whatever
                  // the label did not use was simply lost - the row packed
                  // left and the chevron stopped short, leaving the
                  // chevrons ragged down the group. One Expanded row that
                  // always fills, with spaceBetween inside it, pins the
                  // label left and the value hard against the chevron.
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: color,
                            ),
                          ),
                        ),
                        if (value != null) ...[
                          const SizedBox(width: AppSpacing.sm),
                          Flexible(
                            child: Text(
                              value!,
                              textAlign: TextAlign.end,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.caption.copyWith(
                                color: context.colorInkMuted,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: context.colorInkMuted,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            color: context.colorBorder,
            indent: AppSpacing.md,
            endIndent: AppSpacing.md,
          ),
      ],
    );
  }
}
