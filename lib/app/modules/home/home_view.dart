import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_button.dart';
import 'home_controller.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final user = controller.user;

    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("You're signed in", style: AppTextStyles.heading1),
            const SizedBox(height: 8),
            Text(
              user?.fullName?.isNotEmpty == true
                  ? 'Welcome, ${user!.fullName}'
                  : (user?.email ?? ''),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const Spacer(),
            Obx(
              () => AppButton(
                label: 'Sign out',
                variant: AppButtonVariant.outlined,
                isLoading: controller.isSigningOut.value,
                onPressed: controller.signOut,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
