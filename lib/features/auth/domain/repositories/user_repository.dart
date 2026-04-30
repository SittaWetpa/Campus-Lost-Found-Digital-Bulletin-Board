import 'package:campus_lost_found/features/auth/domain/entities/user.dart';

abstract interface class UserRepository {
  Stream<User?> watchUser(String uid);
  Future<User?> getUserById(String uid);
  Future<void> createUserProfile(User user);
  Future<void> updateUserProfile(User user);
}