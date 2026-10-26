import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/localization/locale_keys.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_brand_header.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_code_field.dart';
import '../../../core/widgets/app_text_field.dart';
import 'forgot_password_controller.dart';

class ForgotPasswordView extends GetView<ForgotPasswordController> {
  const ForgotPasswordView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final step = controller.step.value;
      // Only the email step leaves the screen on a system back gesture;
      // later steps step back instead (see ForgotPasswordController.goBack).
      return PopScope(
        canPop: step == ForgotPasswordStep.email,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) controller.goBack();
        },
        child: Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: controller.goBack,
            ),
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: switch (step) {
                ForgotPasswordStep.email => _EmailStep(controller: controller),
                ForgotPasswordStep.code => _CodeStep(controller: controller),
                ForgotPasswordStep.newPassword => _NewPasswordStep(
                  controller: controller,
                ),
              },
            ),
          ),
        ),
      );
    });
  }
}

class _EmailStep extends StatelessWidget {
  const _EmailStep({required this.controller});

  final ForgotPasswordController controller;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Form(
        key: controller.emailFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppBrandHeader(iconSize: 40),
            const SizedBox(height: AppSpacing.md),
            Text(
              LocaleKeys.forgotPasswordTitle.tr,
              style: AppTextStyles.heading1,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              LocaleKeys.forgotPasswordSubtitle.tr,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              label: LocaleKeys.commonEmail.tr,
              controller: controller.emailController,
              hintText: 'you@example.com',
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.email],
              prefixIcon: Icons.mail_outline,
              validator: Validators.email,
              onFieldSubmitted: (_) => controller.sendCode(),
            ),
            const SizedBox(height: AppSpacing.lg),
            Obx(
              () => AppButton(
                label: LocaleKeys.forgotPasswordButton.tr,
                isLoading: controller.isLoading.value,
                onPressed: controller.sendCode,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CodeStep extends StatelessWidget {
  const _CodeStep({required this.controller});

  final ForgotPasswordController controller;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Form(
        key: controller.codeFormKey,
        child: Column(
          children: [
            const Icon(
              Icons.mark_email_read_outlined,
              size: 64,
              color: AppColors.accent,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              LocaleKeys.forgotPasswordCheckEmailTitle.tr,
              style: AppTextStyles.heading2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              LocaleKeys.forgotPasswordCheckEmailBody.trParams({
                'email': controller.emailController.text.trim(),
              }),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppCodeField(
              controller: controller.codeController,
              onSubmitted: controller.verifyCode,
            ),
            const SizedBox(height: AppSpacing.lg),
            Obx(
              () => AppButton(
                label: LocaleKeys.forgotPasswordVerifyButton.tr,
                isLoading: controller.isLoading.value,
                onPressed: controller.verifyCode,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Obx(() {
              final seconds = controller.resendSecondsLeft.value;
              return AppButton(
                label: seconds > 0
                    ? LocaleKeys.forgotPasswordResendIn.trParams({
                        'seconds': '$seconds',
                      })
                    : LocaleKeys.forgotPasswordResend.tr,
                variant: AppButtonVariant.text,
                isLoading: controller.isResending.value,
                onPressed: seconds > 0 ? null : controller.resendCode,
              );
            }),
            AppButton(
              label: LocaleKeys.forgotPasswordChangeEmail.tr,
              variant: AppButtonVariant.text,
              onPressed: controller.goBack,
            ),
          ],
        ),
      ),
    );
  }
}

class _NewPasswordStep extends StatelessWidget {
  const _NewPasswordStep({required this.controller});

  final ForgotPasswordController controller;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Form(
        key: controller.passwordFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppBrandHeader(iconSize: 40),
            const SizedBox(height: AppSpacing.md),
            Text(
              LocaleKeys.forgotPasswordNewTitle.tr,
              style: AppTextStyles.heading1,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              LocaleKeys.forgotPasswordNewSubtitle.tr,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              label: LocaleKeys.forgotPasswordNewPassword.tr,
              controller: controller.passwordController,
              obscureText: true,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.newPassword],
              prefixIcon: Icons.lock_outline,
              validator: Validators.password,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: LocaleKeys.signupConfirmPassword.tr,
              controller: controller.confirmPasswordController,
              obscureText: true,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.newPassword],
              prefixIcon: Icons.lock_outline,
              validator: (v) => Validators.confirmPassword(
                v,
                controller.passwordController.text,
              ),
              onFieldSubmitted: (_) => controller.savePassword(),
            ),
            const SizedBox(height: AppSpacing.lg),
            Obx(
              () => AppButton(
                label: LocaleKeys.forgotPasswordSaveButton.tr,
                isLoading: controller.isLoading.value,
                onPressed: controller.savePassword,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
