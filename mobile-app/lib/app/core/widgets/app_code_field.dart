import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_text_styles.dart';
import '../utils/validators.dart';

/// The one-time-code input used wherever the app emails a code: password
/// reset and email change. Big, centred and digits-only, so the code reads
/// like a code rather than a form field.
class AppCodeField extends StatelessWidget {
  const AppCodeField({super.key, required this.controller, this.onSubmitted});

  final TextEditingController controller;
  final VoidCallback? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final codeStyle = AppTextStyles.heading2.copyWith(letterSpacing: 8);

    return TextFormField(
      controller: controller,
      autofocus: true,
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.done,
      // Lets iOS offer the code straight from the Mail app.
      autofillHints: const [AutofillHints.oneTimeCode],
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(10),
      ],
      textAlign: TextAlign.center,
      style: codeStyle,
      decoration: InputDecoration(
        hintText: '000000',
        hintStyle: codeStyle.copyWith(color: Theme.of(context).hintColor),
      ),
      validator: Validators.oneTimeCode,
      onFieldSubmitted: (_) => onSubmitted?.call(),
    );
  }
}
