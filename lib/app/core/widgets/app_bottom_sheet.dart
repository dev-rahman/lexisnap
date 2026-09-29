import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Every bottom sheet in the app goes through here.
///
/// There were twelve `showModalBottomSheet` calls scattered across seven
/// files, each repeating the same background colour and the same rounded
/// shape - and one of them had already drifted to a non-const border. A
/// sheet is a single component with a single look, so the look belongs in
/// one place. Background and shape come from `AppTheme`'s
/// `bottomSheetTheme`, which is why neither is passed here.
///
/// [maxHeightFraction] caps the whole sheet - handle included - at that
/// share of the screen. The builder's content must then scroll on its own,
/// since the sheet stops growing; the handle stays pinned above it.
Future<T?> showAppSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool isScrollControlled = false,
  double? maxHeightFraction,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    constraints: maxHeightFraction == null
        ? null
        : BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * maxHeightFraction,
          ),
    builder: (sheetContext) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const _SheetHandle(),
        Flexible(child: builder(sheetContext)),
      ],
    ),
  );
}

/// The grab handle at the top of every sheet.
///
/// Hand-rolled rather than Material's `showDragHandle`, for one reason:
/// Material centres its pill inside a 48dp minimum tap target, which puts
/// roughly 24dp of empty sheet above a 4dp line and no theme value can
/// reduce it. Owning the widget is the only way to control that gap.
///
/// What is kept from Material's version is the part that isn't decoration:
/// the semantics. Screen readers get a labelled, dismissible element
/// rather than an unannounced coloured box. The sheet itself stays
/// draggable from anywhere, so nothing is lost by the handle not being a
/// drag target in its own right.
class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      onTap: () => Navigator.maybePop(context),
      child: Padding(
        padding: const EdgeInsets.only(
          top: AppSpacing.sm,
          bottom: AppSpacing.md,
        ),
        child: Center(
          child: Container(
            height: 4,
            width: 36,
            decoration: BoxDecoration(
              // An affordance, not something to read.
              color: context.colorInkMuted.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ),
    );
  }
}
