abstract interface class StorageRepository {
  /// Uploads [bytes] to [storagePath] and returns the public download URL.
  /// Recommended path convention: `items/{userId}/{uuid}.jpg`
  Future<String> uploadBytes(List<int> bytes, String storagePath);

  /// Deletes a Storage object by its download [url]. No-op if the object
  /// no longer exists (e.g. already deleted or never uploaded).
  Future<void> deleteByUrl(String url);
}
