import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

abstract interface class ProfileRemoteDatasource {
  Future<void> updateProfile({
    required String uid,
    required String firstName,
    required String lastName,
    required String telephone,
  });

  /// Uploads avatar bytes to Storage at `avatars/{uid}.{extension}`,
  /// then writes the download URL back to `users/{uid}.avatarUrl`.
  /// Returns the public download URL.
  Future<String> uploadAvatar({
    required String uid,
    required Uint8List bytes,
    required String extension,
  });
}

class FirebaseProfileDatasource implements ProfileRemoteDatasource {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  const FirebaseProfileDatasource(this._firestore, this._storage);

  @override
  Future<void> updateProfile({
    required String uid,
    required String firstName,
    required String lastName,
    required String telephone,
  }) async {
    await _firestore.collection('users').doc(uid).update({
      'firstName': firstName,
      'lastName': lastName,
      'telephone': telephone,
    });
  }

  @override
  Future<String> uploadAvatar({
    required String uid,
    required Uint8List bytes,
    required String extension,
  }) async {
    // Path intentionally has no extension — content-type is declared via
    // SettableMetadata and Storage rules match on the uid segment exactly.
    final ref = _storage.ref('avatars/$uid');
    final contentType = extension == 'png' ? 'image/png' : 'image/jpeg';
    await ref.putData(bytes, SettableMetadata(contentType: contentType));
    final downloadUrl = await ref.getDownloadURL();
    await _firestore.collection('users').doc(uid).update({
      'avatarUrl': downloadUrl,
    });
    return downloadUrl;
  }
}
