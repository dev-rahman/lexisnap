import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/localization/locale_keys.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/confirm_sheet.dart';
import 'delete_account_controller.dart';

class DeleteAccountView extends GetView<DeleteAccountController> {
  const DeleteAccountView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final step = controller.step.value;
      final isBusy =
          controller.isDeleting.value || controller.isCheckingPassword.value;

      return PopScope(
        // Nothing may leave mid-deletion; otherwise the confirm step backs
        // up to the warning instead of leaving outright.
        canPop: step == DeleteAccountStep.warning && !isBusy,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop && !isBusy) controller.goBack();
        },
        child: Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: isBusy ? null : controller.goBack,
            ),
          ),
          body: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: switch (step) {
                DeleteAccountStep.warning => _WarningStep(
                  controller: controller,
                ),
                DeleteAccountStep.confirm => _ConfirmStep(
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

/// Level one: exactly what goes, and that it can't come back.
class _WarningStep extends StatelessWidget {
  const _WarningStep({required this.controller});

  final DeleteAccountController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _AlertBadge(icon: Icons.warning_amber_rounded),
        const SizedBox(height: AppSpacing.md),
        Text(LocaleKeys.deleteTitle.tr, style: AppTextStyles.heading1),
        const SizedBox(height: AppSpacing.sm),
        Text(
          LocaleKeys.deleteIntro.tr,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: context.colorSurface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Column(
            children: [
              _LossRow(
                icon: Icons.style_outlined,
                text: LocaleKeys.deleteItemDecks.tr,
              ),
              const SizedBox(height: AppSpacing.md),
              _LossRow(
                icon: Icons.local_fire_department_outlined,
                text: LocaleKeys.deleteItemProgress.tr,
              ),
              const SizedBox(height: AppSpacing.md),
              _LossRow(
                icon: Icons.person_off_outlined,
                text: LocaleKeys.deleteItemProfile.tr,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _PermanentNote(text: LocaleKeys.deletePermanentNote.tr),
        const SizedBox(height: AppSpacing.lg),
        // Keeping the account is the filled, obvious button; going on is
        // the quieter one. The safe choice should be the easy one.
        AppButton(label: LocaleKeys.deleteKeepAccount.tr, onPressed: Get.back),
        const SizedBox(height: AppSpacing.sm),
        AppButton(
          label: LocaleKeys.deleteContinue.tr,
          variant: AppButtonVariant.outlined,
          color: AppColors.alert,
          onPressed: controller.continueToConfirm,
        ),
      ],
    );
  }
}

/// Level two: tick, type, and - for password accounts - sign. Level three
/// is the sheet [_submit] shows after all of this passes.
class _ConfirmStep extends StatelessWidget {
  const _ConfirmStep({required this.controller});

  final DeleteAccountController controller;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: controller.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _AlertBadge(icon: Icons.gpp_maybe_outlined),
          const SizedBox(height: AppSpacing.md),
          Text(LocaleKeys.deleteConfirmTitle.tr, style: AppTextStyles.heading1),
          const SizedBox(height: AppSpacing.md),
          _PermanentNote(text: LocaleKeys.deletePermanentNote.tr),
          const SizedBox(height: AppSpacing.md),
          Obx(
            () => Material(
              color: context.colorSurface,
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: InkWell(
                borderRadius: BorderRadius.circular(AppRadius.md),
                onTap: () => controller.understood.toggle(),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xs,
                    AppSpacing.sm,
                    AppSpacing.md,
                    AppSpacing.sm,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Checkbox(
                        value: controller.understood.value,
                        activeColor: AppColors.alert,
                        onChanged: (v) =>
                            controller.understood.value = v ?? false,
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            LocaleKeys.deleteConfirmUnderstand.tr,
                            style: AppTextStyles.body,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: LocaleKeys.deleteConfirmTypeLabel.trParams({
              'word': DeleteAccountController.confirmWord,
            }),
            controller: controller.confirmWordController,
            hintText: DeleteAccountController.confirmWord,
            textInputAction: controller.hasPassword
                ? TextInputAction.next
                : TextInputAction.done,
            validator: controller.validateConfirmWord,
          ),
          if (controller.hasPassword) ...[
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: LocaleKeys.passwordCurrent.tr,
              controller: controller.passwordController,
              obscureText: true,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              prefixIcon: Icons.lock_outline,
              validator: (v) => Validators.required(
                v,
                message: LocaleKeys.validatorPasswordRequired.tr,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          Obx(
            () => AppButton(
              label: LocaleKeys.deleteConfirmButton.tr,
              color: AppColors.alert,
              isLoading:
                  controller.isCheckingPassword.value ||
                  controller.isDeleting.value,
              onPressed: controller.canDelete
                  ? () => _submit(context, controller)
                  : null,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Obx(
            () => AppButton(
              label: LocaleKeys.deleteKeepAccount.tr,
              variant: AppButtonVariant.text,
              onPressed: controller.isDeleting.value ? null : Get.back,
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _submit(
  BuildContext context,
  DeleteAccountController controller,
) async {
  if (!controller.formKey.currentState!.validate()) return;
  if (!await controller.checkPassword()) return;
  if (!context.mounted) return;

  final confirmed = await showConfirmSheet(
    context,
    icon: Icons.delete_forever_rounded,
    title: LocaleKeys.deleteFinalTitle.tr,
    body: LocaleKeys.deleteFinalBody.tr,
    confirmLabel: LocaleKeys.deleteFinalButton.tr,
  );
  if (confirmed) await controller.deleteAccount();
}

class _AlertBadge extends StatelessWidget {
  const _AlertBadge({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        height: 56,
        width: 56,
        decoration: BoxDecoration(
          color: AppColors.alert.withValues(alpha: isDark ? 0.28 : 0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 28,
          color: isDark ? Colors.white : AppColors.alert,
        ),
      ),
    );
  }
}

class _LossRow extends StatelessWidget {
  const _LossRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 22, color: context.colorInk),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: Text(text, style: AppTextStyles.bodyMedium)),
      ],
    );
  }
}

/// The "no way back" line, set apart in solid alert red so it can't be
/// skimmed past as one more paragraph.
class _PermanentNote extends StatelessWidget {
  const _PermanentNote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.alert,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.block_rounded, size: 20, color: Colors.white),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.body.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
