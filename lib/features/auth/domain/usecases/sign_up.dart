import 'package:campus_lost_found/core/constants/app_constants.dart';
import 'package:campus_lost_found/core/errors/failures.dart';
import 'package:campus_lost_found/features/auth/domain/entities/user.dart';
import 'package:campus_lost_found/features/auth/domain/repositories/auth_repository.dart';
import 'package:campus_lost_found/features/auth/domain/repositories/user_repository.dart';

class SignUp {
  final AuthRepository _authRepository;
  final UserRepository _userRepository;
  const SignUp(this._authRepository, this._userRepository);

  Future<void> call({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String studentId,
    required String telephone,
  }) async {
    if (!email.endsWith(AppConstants.emailDomain)) {
      throw const InvalidDomainFailure();
    }
    final authUser = await _authRepository.signUp(email: email, password: password);
    await _userRepository.createUserProfile(
      User(
        uid: authUser.uid,
        email: authUser.email,
        firstName: firstName,
        lastName: lastName,
        studentId: studentId,
        telephone: telephone,
        emailVerified: false,
        createdAt: DateTime.now(),
      ),
    );
  }
}