import 'package:campus_lost_found/core/services/storage_repository.dart';

/// WBS 1.4 — uploads up to 3 post photos. The 3-photo cap is a domain rule
/// (mirrors the mock's `if (f.imageUrls.length >= 3)` check).
///
/// Reuses the existing [StorageRepository]; no new repository interface.
class UploadPostPhotosUseCase {
  final StorageRepository _storage;
  const UploadPostPhotosUseCase(this._storage);

  /// Uploads up to 3 photos for a post. Throws [ArgumentError] if more than
  /// 3 are passed. Returns download URLs in the same order as input.
  ///
  /// Path convention: `items/{userId}/{millis}-{index}.jpg`
  Future<List<String>> call({
    required String userId,
    required List<List<int>> photoBytes,
  }) async {
    if (photoBytes.length > 3) {
      throw ArgumentError('Maximum 3 photos per post');
    }
    final ts = DateTime.now().millisecondsSinceEpoch;
    final urls = <String>[];
    for (var i = 0; i < photoBytes.length; i++) {
      final url = await _storage.uploadBytes(
        photoBytes[i],
        'items/$userId/$ts-$i.jpg',
      );
      urls.add(url);
    }
    return urls;
  }
}
