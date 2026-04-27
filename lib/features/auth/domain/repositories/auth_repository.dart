import 'package:campus_lost_found/features/auth/domain/entities/auth_user.dart';

abstract interface class AuthRepository {
  Stream<AuthUser?> get authStateChanges;
  Future<AuthUser> signIn({required String email, required String password});
  Future<AuthUser> signUp({required String email, required String password});
  Future<void> signOut();
}
