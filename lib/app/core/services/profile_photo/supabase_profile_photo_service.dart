import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import 'profile_photo_service.dart';

/// Keeps profile photos in the public `avatars` Storage bucket, one folder
/// per user (`avatars/<user id>/...`). The bucket and the policies limiting
/// each user to their own folder are created by the
/// `profile_photos` migration.
class SupabaseProfilePhotoService implements ProfilePhotoService {
  static const _bucket = 'avatars';

  sb.StorageFileApi get _files =>
      sb.Supabase.instance.client.storage.from(_bucket);

  @override
  Future<String> upload({
    required String userId,
    required Uint8List bytes,
    required String contentType,
  }) async {
    // A fresh file name each time rather than overwriting one: the public
    // URL is cached by the CDN and by the app's image cache, so reusing it
    // would keep showing the old photo. That also makes the file safe to
    // cache for a year.
    final extension = switch (contentType) {
      'image/png' => 'png',
      'image/webp' => 'webp',
      _ => 'jpg',
    };
    final path = '$userId/${DateTime.now().millisecondsSinceEpoch}.$extension';

    try {
      await _files.uploadBinary(
        path,
        bytes,
        fileOptions: sb.FileOptions(
          contentType: contentType,
          cacheControl: '31536000',
        ),
      );
      return _files.getPublicUrl(path);
    } on sb.StorageException catch (e) {
      throw ProfilePhotoException(e.message);
    }
  }

  @override
  Future<void> prune({required String userId, String? keepUrl}) async {
    try {
      final stale = (await _files.list(path: userId))
          .map((file) => '$userId/${file.name}')
          .where((path) => _files.getPublicUrl(path) != keepUrl)
          .toList();
      if (stale.isNotEmpty) await _files.remove(stale);
    } on sb.StorageException catch (e) {
      throw ProfilePhotoException(e.message);
    }
  }
}
