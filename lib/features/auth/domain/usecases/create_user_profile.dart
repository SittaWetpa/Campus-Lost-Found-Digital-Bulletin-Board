import 'package:campus_lost_found/features/auth/domain/entities/user.dart';
import 'package:campus_lost_found/features/auth/domain/repositories/user_repository.dart';

class CreateUserProfile {
  final UserRepository _repository;
  const CreateUserProfile(this._repository);

  Future<void> call(User user) => _repository.createUserProfile(user);
}