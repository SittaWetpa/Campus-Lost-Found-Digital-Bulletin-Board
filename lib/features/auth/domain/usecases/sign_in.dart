import 'package:campus_lost_found/core/constants/app_constants.dart';
import 'package:campus_lost_found/core/errors/failures.dart';
import 'package:campus_lost_found/features/auth/domain/entities/auth_user.dart';
import 'package:campus_lost_found/features/auth/domain/repositories/auth_repository.dart';

class SignIn {
  final AuthRepository _repository;
  const SignIn(this._repository);

  Future<AuthUser> call({required String email, required String password}) {
    if (!email.endsWith(AppConstants.emailDomain)) {
      throw const InvalidDomainFailure();
    }
    return _repository.signIn(email: email, password: password);
  }
}