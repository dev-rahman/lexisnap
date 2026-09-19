import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import 'help_controller.dart';

class HelpView extends GetView<HelpController> {
  const HelpView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & support'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: Get.back,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Frequently asked questions', style: AppTextStyles.heading2),
              const SizedBox(height: AppSpacing.md),
              Obx(
                () => Column(
                  children: [
                    for (var i = 0; i < HelpController.faqs.length; i++)
                      _FaqTile(
                        entry: HelpController.faqs[i],
                        isExpanded: controller.expandedFaqIndex.value == i,
                        onTap: () => controller.toggleFaq(i),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg * 1.5),
              Text('Still need help?', style: AppTextStyles.heading2),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Send us a message and we\'ll get back to you by email.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'Your message',
                controller: controller.messageController,
                hintText: 'What do you need help with?',
                maxLines: 5,
                textInputAction: TextInputAction.newline,
              ),
              const SizedBox(height: AppSpacing.md),
              Obx(
                () => AppButton(
                  label: 'Email support',
                  icon: const Icon(
                    Icons.mail_outline,
                    color: Colors.white,
                    size: 18,
                  ),
                  isLoading: controller.isSendingMessage.value,
                  onPressed: controller.contactSupport,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FaqTile extends StatelessWidget {
  const _FaqTile({
    required this.entry,
    required this.isExpanded,
    required this.onTap,
  });

  final FaqEntry entry;
  final bool isExpanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: context.colorSurface,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.question,
                        style: AppTextStyles.bodyMedium,
                      ),
                    ),
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: context.colorInkMuted,
                      ),
                    ),
                  ],
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  child: isExpanded
                      ? Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.sm),
                          child: Text(
                            entry.answer,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
