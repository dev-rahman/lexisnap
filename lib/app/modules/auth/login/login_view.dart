import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/localization/locale_keys.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_brand_header.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/app_top_safe_area.dart';
import '../../../core/widgets/language_selector.dart';
import '../../../core/widgets/or_divider.dart';
import '../../../core/widgets/social_sign_in_button.dart';
import 'login_controller.dart';

class LoginView extends GetView<LoginController> {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        top: false,
        child: AppTopSafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: Form(
              key: controller.formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Expanded(child: AppBrandHeader()),
                      const LanguageSelector(),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    LocaleKeys.loginWelcomeBack.tr,
                    style: AppTextStyles.heading1,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    LocaleKeys.loginSubtitle.tr,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.lg),
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
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.password],
                    prefixIcon: Icons.lock_outline,
                    validator: Validators.password,
                    onFieldSubmitted: (_) => controller.submitEmailLogin(),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: controller.goToForgotPassword,
                      child: Text(LocaleKeys.loginForgotPassword.tr),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Obx(
                    () => AppButton(
                      label: LocaleKeys.loginButton.tr,
                      isLoading: controller.isEmailLoading.value,
                      onPressed: controller.submitEmailLogin,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const OrDivider(),
                  const SizedBox(height: AppSpacing.lg),
                  Obx(
                    () => SocialSignInButton(
                      provider: SocialProvider.google,
                      isLoading: controller.isGoogleLoading.value,
                      onPressed: controller.continueWithGoogle,
                    ),
                  ),
                  if (GetPlatform.isIOS) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Obx(
                      () => SocialSignInButton(
                        provider: SocialProvider.apple,
                        isLoading: controller.isAppleLoading.value,
                        onPressed: controller.continueWithApple,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(LocaleKeys.loginNoAccount.tr),
                      TextButton(
                        onPressed: controller.goToSignUp,
                        child: Text(LocaleKeys.loginSignUp.tr),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
