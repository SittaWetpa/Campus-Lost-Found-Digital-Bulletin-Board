import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:campus_lost_found/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:campus_lost_found/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:campus_lost_found/features/auth/domain/entities/auth_user.dart';
import 'package:campus_lost_found/features/auth/domain/repositories/auth_repository.dart';
import 'package:campus_lost_found/features/auth/domain/usecases/sign_in.dart';

part 'auth_provider.g.dart';

@riverpod
AuthRemoteDatasource authDatasource(AuthDatasourceRef ref) {
  return FirebaseAuthDatasource(FirebaseAuth.instance);
}

@riverpod
AuthRepository authRepository(AuthRepositoryRef ref) {
  return AuthRepositoryImpl(ref.watch(authDatasourceProvider));
}

@riverpod
Stream<AuthUser?> authState(AuthStateRef ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
}

@riverpod
class LoginNotifier extends _$LoginNotifier {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> signIn({required String email, required String password}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await SignIn(ref.read(authRepositoryProvider)).call(
        email: email,
        password: password,
      );
    });
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).signOut(),
    );
  }
}