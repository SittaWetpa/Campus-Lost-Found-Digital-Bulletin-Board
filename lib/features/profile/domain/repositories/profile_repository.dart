abstract interface class ProfileRepository {
  /// Updates firstName, lastName, telephone in Firestore users/{uid}.
  Future<void> updateProfile({
    required String uid,
    required String firstName,
    required String lastName,
    required String telephone,
  });

  /// Uploads image bytes to Firebase Storage then updates avatarUrl in Firestore.
  /// [extension] must be 'jpg' or 'png' (lowercase, no leading dot).
  Future<void> uploadAvatar({
    required String uid,
    required List<int> bytes,
    required String extension,
  });
}
