import 'package:campus_lost_found/core/errors/failures.dart';
import 'package:campus_lost_found/features/auth/data/datasources/user_remote_datasource.dart';
import 'package:campus_lost_found/features/auth/data/models/user_model.dart';
import 'package:campus_lost_found/features/auth/domain/entities/user.dart';
import 'package:campus_lost_found/features/auth/domain/repositories/user_repository.dart';

class UserRepositoryImpl implements UserRepository {
  final UserRemoteDatasource _datasource;
  const UserRepositoryImpl(this._datasource);

  @override
  Stream<User?> watchUser(String uid) {
    return _datasource.watchUser(uid).map((model) => model?.toEntity());
  }

  @override
  Future<User?> getUserById(String uid) async {
    final model = await _datasource.getUserById(uid);
    return model?.toEntity();
  }

  @override
  Future<void> createUserProfile(User user) async {
    try {
      await _datasource.createUser(UserModel.fromEntity(user));
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<void> updateUserProfile(User user) async {
    try {
      await _datasource.updateUser(UserModel.fromEntity(user));
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }
}