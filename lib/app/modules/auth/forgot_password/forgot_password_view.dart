import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_brand_header.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import 'forgot_password_controller.dart';

class ForgotPasswordView extends GetView<ForgotPasswordController> {
  const ForgotPasswordView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: Get.back,
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Obx(
            () => controller.emailSent.value
                ? _SentConfirmation(email: controller.emailController.text)
                : _ForgotPasswordForm(controller: controller),
          ),
        ),
      ),
    );
  }
}

class _ForgotPasswordForm extends StatelessWidget {
  const _ForgotPasswordForm({required this.controller});

  final ForgotPasswordController controller;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Form(
        key: controller.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppBrandHeader(iconSize: 40),
            const SizedBox(height: AppSpacing.md),
            Text('Reset your password', style: AppTextStyles.heading1),
            const SizedBox(height: AppSpacing.sm),
            Text(
              "Enter your email and we'll send you a link to reset your password.",
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              label: 'Email',
              controller: controller.emailController,
              hintText: 'you@example.com',
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.email],
              prefixIcon: Icons.mail_outline,
              validator: Validators.email,
              onFieldSubmitted: (_) => controller.submit(),
            ),
            const SizedBox(height: AppSpacing.lg),
            Obx(
              () => AppButton(
                label: 'Send reset link',
                isLoading: controller.isLoading.value,
                onPressed: controller.submit,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SentConfirmation extends StatelessWidget {
  const _SentConfirmation({required this.email});

  final String email;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.mark_email_read_outlined, size: 64, color: AppColors.accent),
        const SizedBox(height: AppSpacing.lg),
        Text('Check your email', style: AppTextStyles.heading2, textAlign: TextAlign.center),
        const SizedBox(height: AppSpacing.sm),
        Text(
          "We've sent a password reset link to $email",
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.lg),
        AppButton(
          label: 'Back to login',
          variant: AppButtonVariant.outlined,
          onPressed: Get.back,
        ),
      ],
    );
  }
}
