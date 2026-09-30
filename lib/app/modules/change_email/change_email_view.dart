import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/localization/locale_keys.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_code_field.dart';
import '../../core/widgets/app_text_field.dart';
import 'change_email_controller.dart';

class ChangeEmailView extends GetView<ChangeEmailController> {
  const ChangeEmailView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final step = controller.step.value;
      // Only the first step leaves the screen on a system back gesture;
      // the code steps go back to the address instead.
      return PopScope(
        canPop: step == ChangeEmailStep.newEmail,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) controller.goBack();
        },
        child: Scaffold(
          appBar: AppBar(
            title: Text(LocaleKeys.emailChangeTitle.tr),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: controller.goBack,
            ),
          ),
          body: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: switch (step) {
                ChangeEmailStep.newEmail => _EmailStep(controller: controller),
                ChangeEmailStep.newCode => _CodeStep(
                  controller: controller,
                  title: LocaleKeys.emailChangeCodeNewTitle.tr,
                  body: LocaleKeys.emailChangeCodeNewBody.trParams({
                    'email': controller.newEmail,
                  }),
                ),
                ChangeEmailStep.currentCode => _CodeStep(
                  controller: controller,
                  title: LocaleKeys.emailChangeCodeCurrentTitle.tr,
                  body: LocaleKeys.emailChangeCodeCurrentBody.trParams({
                    'email': controller.currentEmail,
                  }),
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

  final ChangeEmailController controller;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Form(
        key: controller.emailFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              LocaleKeys.emailChangeSubtitle.tr,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              LocaleKeys.emailChangeCurrent.trParams({
                'email': controller.currentEmail,
              }),
              style: AppTextStyles.caption.copyWith(
                color: context.colorInkMuted,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              label: LocaleKeys.emailChangeNewLabel.tr,
              controller: controller.emailController,
              hintText: 'you@example.com',
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.email],
              prefixIcon: Icons.mail_outline,
              validator: controller.validateNewEmail,
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
  const _CodeStep({
    required this.controller,
    required this.title,
    required this.body,
  });

  final ChangeEmailController controller;
  final String title;
  final String body;

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
              title,
              style: AppTextStyles.heading2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              body,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppCodeField(
              // A new key per step, so moving to the second code gives a
              // fresh field rather than reusing the first one's state.
              key: ValueKey(controller.step.value),
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
