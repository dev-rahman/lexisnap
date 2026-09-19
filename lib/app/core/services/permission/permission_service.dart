import 'package:permission_handler/permission_handler.dart';

/// The three outcomes the rest of the app actually branches on, instead of
/// `permission_handler`'s full [PermissionStatus] enum.
enum AppPermissionStatus { granted, denied, permanentlyDenied }

/// Thin wrapper around `permission_handler`. Exposes `<x>Status` (a
/// non-prompting check) separately from `request<X>` (which may show the OS
/// prompt), so callers can decide whether to show an explanatory primer
/// before ever triggering the system dialog.
class PermissionService {
  Future<AppPermissionStatus> cameraStatus() => _map(Permission.camera.status);

  Future<AppPermissionStatus> requestCamera() =>
      _map(Permission.camera.request());

  Future<AppPermissionStatus> photosStatus() => _map(Permission.photos.status);

  Future<AppPermissionStatus> requestPhotos() =>
      _map(Permission.photos.request());

  Future<void> openSettings() => openAppSettings();

  Future<AppPermissionStatus> _map(Future<PermissionStatus> future) async {
    final status = await future;
    if (status.isGranted || status.isLimited) {
      return AppPermissionStatus.granted;
    }
    if (status.isPermanentlyDenied) {
      return AppPermissionStatus.permanentlyDenied;
    }
    return AppPermissionStatus.denied;
  }
}
