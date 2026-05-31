import 'package:campus_lost_found/core/errors/failures.dart';
import 'package:campus_lost_found/features/profile/domain/repositories/profile_repository.dart';

class UpdateProfile {
  final ProfileRepository _repository;
  const UpdateProfile(this._repository);

  Future<void> call({
    required String uid,
    required String firstName,
    required String lastName,
    required String telephone,
  }) {
    if (firstName.trim().isEmpty) {
      throw const ProfileFailure('First name cannot be empty.');
    }
    if (lastName.trim().isEmpty) {
      throw const ProfileFailure('Last name cannot be empty.');
    }
    if (!RegExp(r'^0\d{9}$').hasMatch(telephone)) {
      throw const ProfileFailure(
        'Telephone must be a 10-digit Thai number starting with 0.',
      );
    }
    return _repository.updateProfile(
      uid: uid,
      firstName: firstName.trim(),
      lastName: lastName.trim(),
      telephone: telephone,
    );
  }
}
