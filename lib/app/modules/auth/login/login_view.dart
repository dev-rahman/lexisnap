import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/or_divider.dart';
import '../../../core/widgets/social_sign_in_button.dart';
import 'login_controller.dart';

class LoginView extends GetView<LoginController> {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Form(
            key: controller.formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Welcome back', style: AppTextStyles.heading1),
                const SizedBox(height: 8),
                Text(
                  'Sign in to continue',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 32),
                AppTextField(
                  label: 'Email',
                  controller: controller.emailController,
                  hintText: 'you@example.com',
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  prefixIcon: Icons.mail_outline,
                  validator: Validators.email,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Password',
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
                    child: const Text('Forgot password?'),
                  ),
                ),
                const SizedBox(height: 8),
                Obx(
                  () => AppButton(
                    label: 'Log in',
                    isLoading: controller.isEmailLoading.value,
                    onPressed: controller.submitEmailLogin,
                  ),
                ),
                const SizedBox(height: 24),
                const OrDivider(),
                const SizedBox(height: 24),
                Obx(
                  () => SocialSignInButton(
                    provider: SocialProvider.google,
                    isLoading: controller.isGoogleLoading.value,
                    onPressed: controller.continueWithGoogle,
                  ),
                ),
                if (GetPlatform.isIOS) ...[
                  const SizedBox(height: 12),
                  Obx(
                    () => SocialSignInButton(
                      provider: SocialProvider.apple,
                      isLoading: controller.isAppleLoading.value,
                      onPressed: controller.continueWithApple,
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account?"),
                    TextButton(
                      onPressed: controller.goToSignUp,
                      child: const Text('Sign up'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
