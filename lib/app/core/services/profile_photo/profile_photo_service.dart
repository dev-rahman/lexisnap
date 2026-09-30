import 'dart:typed_data';

/// Stores the signed-in user's profile photo.
///
/// Controllers depend on this interface only; `SupabaseProfilePhotoService`
/// is the Supabase Storage implementation, registered in `ServiceLocator`.
abstract class ProfilePhotoService {
  /// Uploads [bytes] as a new photo for [userId] and returns the URL to
  /// show it from. Earlier photos are left alone - call [prune] once the
  /// profile points at the new one.
  Future<String> upload({
    required String userId,
    required Uint8List bytes,
    required String contentType,
  });

  /// Deletes every photo [userId] has uploaded except the one at [keepUrl],
  /// or all of them when [keepUrl] is null.
  Future<void> prune({required String userId, String? keepUrl});
}

class ProfilePhotoException implements Exception {
  const ProfilePhotoException(this.message);

  final String message;

  @override
  String toString() => message;
}
