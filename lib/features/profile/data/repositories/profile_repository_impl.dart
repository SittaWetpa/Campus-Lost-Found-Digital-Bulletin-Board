import 'dart:typed_data';
import 'package:firebase_core/firebase_core.dart';
import 'package:campus_lost_found/core/errors/failures.dart';
import 'package:campus_lost_found/features/profile/data/datasources/profile_remote_datasource.dart';
import 'package:campus_lost_found/features/profile/domain/repositories/profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDatasource _datasource;
  const ProfileRepositoryImpl(this._datasource);

  @override
  Future<void> updateProfile({
    required String uid,
    required String firstName,
    required String lastName,
    required String telephone,
  }) async {
    try {
      await _datasource.updateProfile(
        uid: uid,
        firstName: firstName,
        lastName: lastName,
        telephone: telephone,
      );
    } on FirebaseException catch (e) {
      throw ProfileFailure(e.message ?? 'Failed to update profile.');
    } catch (_) {
      throw const ProfileFailure('Failed to update profile.');
    }
  }

  @override
  Future<void> uploadAvatar({
    required String uid,
    required List<int> bytes,
    required String extension,
  }) async {
    try {
      await _datasource.uploadAvatar(
        uid: uid,
        bytes: Uint8List.fromList(bytes),
        extension: extension,
      );
    } on FirebaseException catch (e) {
      throw ProfileFailure(e.message ?? 'Failed to upload avatar.');
    } catch (_) {
      throw const ProfileFailure('Failed to upload avatar.');
    }
  }
}
