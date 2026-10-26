import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/errors/auth_exception.dart';
import '../../core/localization/locale_keys.dart';
import '../../core/services/auth/auth_service.dart';
import '../../core/services/auth/user_service.dart';
import '../../core/services/profile_photo/profile_photo_service.dart';
import '../../core/utils/app_snackbar.dart';
import '../../data/models/app_user.dart';
import '../../routes/app_routes.dart';

class EditProfileController extends GetxController {
  /// Photos are shrunk on the phone before they're uploaded. 256px is
  /// already more than the largest avatar in the app needs (96pt on this
  /// screen), and at JPEG quality 70 a photo lands around 15-30 KB.
  static const _photoMaxSide = 256.0;
  static const _photoQuality = 70;

  /// Anything still larger than this after shrinking is refused rather
  /// than uploaded. A PNG - which ignores the quality setting - is the only
  /// realistic way to get here. The bucket's own 256 KB limit backs it up.
  static const _photoMaxBytes = 200 * 1024;

  static const _photoTypes = {'image/jpeg', 'image/png', 'image/webp'};

  AuthService get _authService => Get.find<AuthService>();
  ProfilePhotoService get _photos => Get.find<ProfilePhotoService>();

  /// Reactive: read inside an `Obx`.
  AppUser? get user => Get.find<UserService>().user.value;

  final isPhotoBusy = false.obs;
  final isSavingName = false.obs;
  final isSavingPassword = false.obs;

  final _picker = ImagePicker();

  Future<void> changePhoto(ImageSource source) async {
    final current = user;
    if (current == null) return;

    final file = await _picker.pickImage(
      source: source,
      maxWidth: _photoMaxSide,
      maxHeight: _photoMaxSide,
      imageQuality: _photoQuality,
      preferredCameraDevice: CameraDevice.front,
      requestFullMetadata: false,
    );
    if (file == null) return;

    final contentType = _contentTypeOf(file);
    if (contentType == null) {
      AppSnackbar.error(LocaleKeys.photoUnsupported.tr);
      return;
    }

    isPhotoBusy.value = true;
    try {
      final bytes = await file.readAsBytes();
      if (bytes.length > _photoMaxBytes) {
        AppSnackbar.error(LocaleKeys.photoTooLarge.tr);
        return;
      }

      final url = await _photos.upload(
        userId: current.id,
        bytes: bytes,
        contentType: contentType,
      );
      await _authService.updateProfilePhoto(url);
      _pruneQuietly(current.id, keepUrl: url);
      AppSnackbar.success(LocaleKeys.photoUpdated.tr);
    } on ProfilePhotoException catch (e) {
      AppSnackbar.error(e.message);
    } on AppAuthException catch (e) {
      AppSnackbar.error(e.message);
    } finally {
      isPhotoBusy.value = false;
    }
  }

  Future<void> removePhoto() async {
    final current = user;
    if (current == null) return;

    isPhotoBusy.value = true;
    try {
      await _authService.updateProfilePhoto(null);
      _pruneQuietly(current.id);
      AppSnackbar.success(LocaleKeys.photoRemoved.tr);
    } on AppAuthException catch (e) {
      AppSnackbar.error(e.message);
    } finally {
      isPhotoBusy.value = false;
    }
  }

  /// Returns whether the name was saved, so the sheet knows to close.
  Future<bool> updateName(String fullName) async {
    isSavingName.value = true;
    try {
      await _authService.updateProfile(fullName: fullName);
      AppSnackbar.success(LocaleKeys.profileNameUpdated.tr);
      return true;
    } on AppAuthException catch (e) {
      AppSnackbar.error(e.message);
      return false;
    } finally {
      isSavingName.value = false;
    }
  }

  /// [currentPassword] is null for a Google account setting its
  /// first password - there's nothing to confirm yet. Returns whether the
  /// password was saved, so the sheet knows to close.
  Future<bool> changePassword({
    String? currentPassword,
    required String newPassword,
  }) async {
    isSavingPassword.value = true;
    try {
      if (currentPassword != null) {
        await _authService.reauthenticate(password: currentPassword);
      }
      await _authService.updatePassword(password: newPassword);
      AppSnackbar.success(LocaleKeys.forgotPasswordUpdated.tr);
      return true;
    } on WrongPasswordException {
      AppSnackbar.error(LocaleKeys.passwordWrongCurrent.tr);
      return false;
    } on AppAuthException catch (e) {
      AppSnackbar.error(e.message);
      return false;
    } finally {
      isSavingPassword.value = false;
    }
  }

  void openChangeEmail() => Get.toNamed(AppRoutes.changeEmail);

  void openDeleteAccount() => Get.toNamed(AppRoutes.deleteAccount);

  String? _contentTypeOf(XFile file) {
    final type =
        file.mimeType ??
        switch (file.name.split('.').last.toLowerCase()) {
          'jpg' || 'jpeg' => 'image/jpeg',
          'png' => 'image/png',
          'webp' => 'image/webp',
          _ => null,
        };
    return _photoTypes.contains(type) ? type : null;
  }

  /// Clearing out replaced photos is housekeeping: the profile already
  /// points at the right one, and anything left over goes with the account.
  void _pruneQuietly(String userId, {String? keepUrl}) {
    _photos.prune(userId: userId, keepUrl: keepUrl).catchError((_) {});
  }
}
