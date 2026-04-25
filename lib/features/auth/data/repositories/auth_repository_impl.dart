import 'package:campus_lost_found/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:campus_lost_found/features/auth/domain/entities/auth_user.dart';
import 'package:campus_lost_found/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDatasource _datasource;
  const AuthRepositoryImpl(this._datasource);

  @override
  Stream<AuthUser?> get authStateChanges {
    return _datasource.authStateChanges.map(
      (user) =>
          user == null ? null : AuthUser(uid: user.uid, email: user.email!),
    );
  }

  @override
  Future<AuthUser> signIn(
      {required String email, required String password}) async {
    final user =
        await _datasource.signIn(email: email, password: password);
    return AuthUser(uid: user.uid, email: user.email!);
  }

  @override
  Future<AuthUser> signUp(
      {required String email, required String password}) async {
    final user =
        await _datasource.signUp(email: email, password: password);
    return AuthUser(uid: user.uid, email: user.email!);
  }

  @override
  Future<void> signOut() => _datasource.signOut();
}