import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:campus_lost_found/features/auth/domain/usecases/sign_up.dart';
import 'package:campus_lost_found/features/auth/presentation/providers/auth_provider.dart';
import 'package:campus_lost_found/features/auth/presentation/providers/user_provider.dart';
import 'package:campus_lost_found/features/notifications/presentation/providers/notification_service_provider.dart';

part 'register_provider.g.dart';

@riverpod
class RegisterNotifier extends _$RegisterNotifier {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String studentId,
    required String telephone,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await SignUp(
        ref.read(authRepositoryProvider),
        ref.read(userRepositoryProvider),
      ).call(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        studentId: studentId,
        telephone: telephone,
      );
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        final ns = ref.read(notificationServiceProvider);
        await ns.requestPermission().catchError((_) {});
        ns.registerToken(uid).ignore();
      }
    });
  }
}