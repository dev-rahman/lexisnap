import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/localization/locale_keys.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_brand_header.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import 'signup_controller.dart';

class SignupView extends GetView<SignupController> {
  const SignupView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: controller.goToLogin,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Form(
            key: controller.formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppBrandHeader(iconSize: 40),
                const SizedBox(height: AppSpacing.md),
                Text(LocaleKeys.signupTitle.tr, style: AppTextStyles.heading1),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  LocaleKeys.signupSubtitle.tr,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(
                  label: LocaleKeys.commonFullName.tr,
                  controller: controller.fullNameController,
                  hintText: 'Jane Doe',
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.name],
                  prefixIcon: Icons.person_outline,
                  validator: (v) => Validators.required(
                    v,
                    message: LocaleKeys.signupNameRequired.tr,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: LocaleKeys.commonEmail.tr,
                  controller: controller.emailController,
                  hintText: 'you@example.com',
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  prefixIcon: Icons.mail_outline,
                  validator: Validators.email,
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: LocaleKeys.commonPassword.tr,
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
                  prefixIcon: Icons.lock_outline,
                  validator: (v) => Validators.confirmPassword(
                    v,
                    controller.passwordController.text,
                  ),
                  onFieldSubmitted: (_) => controller.submit(),
                ),
                const SizedBox(height: AppSpacing.lg),
                Obx(
                  () => AppButton(
                    label: LocaleKeys.signupButton.tr,
                    isLoading: controller.isLoading.value,
                    onPressed: controller.submit,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
