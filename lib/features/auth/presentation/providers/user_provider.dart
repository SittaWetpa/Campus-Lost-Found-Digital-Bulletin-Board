import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:campus_lost_found/core/services/sync_metadata_datasource.dart';
import 'package:campus_lost_found/features/auth/data/datasources/user_local_datasource.dart';
import 'package:campus_lost_found/features/auth/data/datasources/user_remote_datasource.dart';
import 'package:campus_lost_found/features/auth/data/repositories/user_repository_impl.dart';
import 'package:campus_lost_found/features/auth/domain/entities/user.dart';
import 'package:campus_lost_found/features/auth/domain/repositories/user_repository.dart';
import 'package:campus_lost_found/features/auth/presentation/providers/auth_provider.dart';

part 'user_provider.g.dart';

@riverpod
UserRemoteDatasource userDatasource(UserDatasourceRef ref) {
  return FirestoreUserDatasource(FirebaseFirestore.instance);
}

@riverpod
UserLocalDatasource userLocalDatasource(UserLocalDatasourceRef ref) {
  return HiveUserLocalDatasource(Hive.box<Map>('user_profile_box'));
}

@riverpod
UserRepository userRepository(UserRepositoryRef ref) {
  return UserRepositoryImpl(
    ref.watch(userDatasourceProvider),
    ref.watch(userLocalDatasourceProvider),
    ref.watch(syncMetadataProvider),
  );
}

@riverpod
Stream<User?> currentUser(CurrentUserRef ref) {
  final authUser = ref.watch(authStateProvider).valueOrNull;
  if (authUser == null) return Stream.value(null);
  return ref.watch(userRepositoryProvider).watchUser(authUser.uid);
}

@riverpod
Future<User?> getUserById(GetUserByIdRef ref, String uid) async {
  // Wait for Firebase Auth to emit before making the Firestore call.
  // On web, auth initializes asynchronously; firing the query before auth
  // resolves causes a permission-denied error (rules require request.auth != null)
  // which Riverpod caches as a permanent null via valueOrNull.
  final authUser = await ref.watch(authStateProvider.future);
  if (authUser == null) return null;
  return ref.watch(userRepositoryProvider).getUserById(uid);
}
