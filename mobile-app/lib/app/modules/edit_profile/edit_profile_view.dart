import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/localization/locale_keys.dart';
import '../../core/services/permission/permission_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/app_avatar.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_settings_group.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/permission_sheets.dart';
import '../../data/models/app_user.dart';
import 'edit_profile_controller.dart';

class EditProfileView extends GetView<EditProfileController> {
  const EditProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(LocaleKeys.editProfileTitle.tr)),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Obx(() {
            final user = controller.user;
            final name = user?.fullName?.isNotEmpty == true
                ? user!.fullName!
                : null;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: _PhotoEditor(
                    user: user,
                    isBusy: controller.isPhotoBusy.value,
                    onTap: () => _showPhotoSheet(context, controller),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                AppSettingsGroup(
                  children: [
                    AppSettingsTile(
                      icon: Icons.person_outline_rounded,
                      label: LocaleKeys.editProfileName.tr,
                      value: name ?? LocaleKeys.editProfileNotSet.tr,
                      onTap: () => _showNameSheet(context, controller, name),
                    ),
                    AppSettingsTile(
                      icon: Icons.mail_outline_rounded,
                      label: LocaleKeys.commonEmail.tr,
                      value: user?.email,
                      onTap: controller.openChangeEmail,
                    ),
                    AppSettingsTile(
                      icon: Icons.lock_outline_rounded,
                      label: LocaleKeys.commonPassword.tr,
                      value: user?.hasPassword == true
                          ? '••••••••'
                          : LocaleKeys.editProfileNotSet.tr,
                      onTap: () => _showPasswordSheet(context, controller),
                      showDivider: false,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Padding(
                  padding: const EdgeInsets.only(
                    left: AppSpacing.md,
                    bottom: AppSpacing.sm,
                  ),
                  child: Text(
                    LocaleKeys.editProfileDangerZone.tr,
                    style: AppTextStyles.caption.copyWith(
                      color: context.colorInkMuted,
                    ),
                  ),
                ),
                AppSettingsGroup(
                  children: [
                    AppSettingsTile(
                      icon: Icons.delete_forever_outlined,
                      label: LocaleKeys.editProfileDeleteAccount.tr,
                      color: AppColors.alert,
                      onTap: controller.openDeleteAccount,
                      showDivider: false,
                    ),
                  ],
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

/// The avatar at the top of the screen, tappable to change it, with a
/// camera badge saying so and a spinner over it while a photo uploads.
class _PhotoEditor extends StatelessWidget {
  const _PhotoEditor({
    required this.user,
    required this.isBusy,
    required this.onTap,
  });

  static const double _size = 96;

  final AppUser? user;
  final bool isBusy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: LocaleKeys.photoSheetTitle.tr,
      child: GestureDetector(
        onTap: isBusy ? null : onTap,
        child: SizedBox.square(
          dimension: _size,
          child: Stack(
            children: [
              Positioned.fill(
                child: Hero(
                  tag: AppAvatar.heroTag,
                  transitionOnUserGestures: true,
                  child: AppAvatar(user: user),
                ),
              ),
              if (isBusy)
                const Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: SizedBox.square(
                        dimension: 28,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  height: 32,
                  width: 32,
                  decoration: BoxDecoration(
                    // Coral: the photo is this screen's main thing to do.
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                    border: Border.all(color: context.colorPaper, width: 3),
                  ),
                  child: const Icon(
                    Icons.photo_camera_rounded,
                    size: 15,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _PhotoAction { take, choose, remove }

Future<void> _showPhotoSheet(
  BuildContext context,
  EditProfileController controller,
) async {
  final hasOwnPhoto = controller.user?.hasOwnPhoto ?? false;

  final action = await showAppSheet<_PhotoAction>(
    context,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        // The drag handle above already reserves the top gap.
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(LocaleKeys.photoSheetTitle.tr, style: AppTextStyles.heading2),
            const SizedBox(height: AppSpacing.md),
            AppSettingsGroup(
              children: [
                AppSettingsTile(
                  icon: Icons.photo_camera_outlined,
                  label: LocaleKeys.photoTake.tr,
                  onTap: () => Navigator.pop(sheetContext, _PhotoAction.take),
                ),
                AppSettingsTile(
                  icon: Icons.photo_library_outlined,
                  label: LocaleKeys.photoChoose.tr,
                  onTap: () => Navigator.pop(sheetContext, _PhotoAction.choose),
                  showDivider: hasOwnPhoto,
                ),
                if (hasOwnPhoto)
                  AppSettingsTile(
                    icon: Icons.delete_outline_rounded,
                    label: LocaleKeys.photoRemove.tr,
                    color: AppColors.alert,
                    onTap: () =>
                        Navigator.pop(sheetContext, _PhotoAction.remove),
                    showDivider: false,
                  ),
              ],
            ),
          ],
        ),
      ),
    ),
  );

  if (action == null || !context.mounted) return;
  switch (action) {
    case _PhotoAction.take:
      final permissions = Get.find<PermissionService>();
      final granted = await ensurePermissionGranted(
        context,
        status: permissions.cameraStatus,
        request: permissions.requestCamera,
        icon: Icons.photo_camera_rounded,
        primerTitle: LocaleKeys.permissionCameraTitle.tr,
        primerBody: LocaleKeys.photoCameraPrimerBody.tr,
        deniedBody: LocaleKeys.photoCameraDeniedBody.tr,
      );
      if (granted) await controller.changePhoto(ImageSource.camera);
    case _PhotoAction.choose:
      // No permission step: the system photo picker only hands over the
      // one photo the user picks, so the app never needs library access.
      await controller.changePhoto(ImageSource.gallery);
    case _PhotoAction.remove:
      await controller.removePhoto();
  }
}

/// Bottom padding for a sheet holding text fields. viewInsets covers the
/// keyboard, padding.bottom the system nav bar - and they swap as the
/// keyboard opens, so both are needed or the button sits under the nav
/// buttons.
double _formSheetBottom(BuildContext sheetContext) =>
    AppSpacing.lg +
    MediaQuery.of(sheetContext).viewInsets.bottom +
    MediaQuery.of(sheetContext).padding.bottom;

void _showNameSheet(
  BuildContext context,
  EditProfileController controller,
  String? currentName,
) {
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController(text: currentName ?? '');

  showAppSheet(
    context,
    isScrollControlled: true,
    builder: (sheetContext) {
      Future<void> save() async {
        if (!formKey.currentState!.validate()) return;
        final saved = await controller.updateName(nameController.text.trim());
        if (saved && sheetContext.mounted) Navigator.pop(sheetContext);
      }

      return Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          _formSheetBottom(sheetContext),
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                LocaleKeys.profileEditName.tr,
                style: AppTextStyles.heading2,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: LocaleKeys.commonFullName.tr,
                controller: nameController,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.name],
                validator: (v) => Validators.required(
                  v,
                  message: LocaleKeys.validatorNameRequired.tr,
                ),
                onFieldSubmitted: (_) => save(),
              ),
              const SizedBox(height: AppSpacing.lg),
              Obx(
                () => AppButton(
                  label: LocaleKeys.commonSave.tr,
                  isLoading: controller.isSavingName.value,
                  onPressed: save,
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

void _showPasswordSheet(
  BuildContext context,
  EditProfileController controller,
) {
  // Google accounts have no password yet, so there's nothing to
  // confirm - they're setting one, not changing it.
  final hasPassword = controller.user?.hasPassword ?? false;
  final formKey = GlobalKey<FormState>();
  final currentController = TextEditingController();
  final newController = TextEditingController();
  final confirmController = TextEditingController();

  showAppSheet(
    context,
    isScrollControlled: true,
    builder: (sheetContext) {
      Future<void> save() async {
        if (!formKey.currentState!.validate()) return;
        final saved = await controller.changePassword(
          currentPassword: hasPassword ? currentController.text : null,
          newPassword: newController.text,
        );
        if (saved && sheetContext.mounted) Navigator.pop(sheetContext);
      }

      return SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          _formSheetBottom(sheetContext),
        ),
        child: Form(
          key: formKey,
          child: AutofillGroup(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasPassword
                      ? LocaleKeys.passwordChangeTitle.tr
                      : LocaleKeys.passwordSetTitle.tr,
                  style: AppTextStyles.heading2,
                ),
                if (!hasPassword) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    LocaleKeys.passwordSetBody.tr,
                    style: AppTextStyles.body.copyWith(
                      color: context.colorInkMuted,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                if (hasPassword) ...[
                  AppTextField(
                    label: LocaleKeys.passwordCurrent.tr,
                    controller: currentController,
                    obscureText: true,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.password],
                    prefixIcon: Icons.lock_outline,
                    validator: (v) => Validators.required(
                      v,
                      message: LocaleKeys.validatorPasswordRequired.tr,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                AppTextField(
                  label: LocaleKeys.forgotPasswordNewPassword.tr,
                  controller: newController,
                  obscureText: true,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.newPassword],
                  prefixIcon: Icons.lock_outline,
                  validator: Validators.password,
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: LocaleKeys.signupConfirmPassword.tr,
                  controller: confirmController,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.newPassword],
                  prefixIcon: Icons.lock_outline,
                  validator: (v) =>
                      Validators.confirmPassword(v, newController.text),
                  onFieldSubmitted: (_) => save(),
                ),
                const SizedBox(height: AppSpacing.lg),
                Obx(
                  () => AppButton(
                    label: LocaleKeys.forgotPasswordSaveButton.tr,
                    isLoading: controller.isSavingPassword.value,
                    onPressed: save,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
