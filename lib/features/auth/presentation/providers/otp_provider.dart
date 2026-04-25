import 'package:cloud_functions/cloud_functions.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:campus_lost_found/features/auth/data/datasources/otp_remote_datasource.dart';
import 'package:campus_lost_found/features/auth/data/repositories/otp_repository_impl.dart';
import 'package:campus_lost_found/features/auth/domain/repositories/otp_repository.dart';
import 'package:campus_lost_found/features/auth/domain/usecases/send_otp.dart';
import 'package:campus_lost_found/features/auth/domain/usecases/verify_otp.dart';

part 'otp_provider.g.dart';

@riverpod
OtpRemoteDatasource otpDatasource(OtpDatasourceRef ref) {
  return CloudFunctionOtpDatasource(
    FirebaseFunctions.instanceFor(region: 'asia-southeast1'),
  );
}

@riverpod
OtpRepository otpRepository(OtpRepositoryRef ref) {
  return OtpRepositoryImpl(ref.watch(otpDatasourceProvider));
}

@riverpod
class OtpNotifier extends _$OtpNotifier {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> sendOtp() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => SendOtp(ref.read(otpRepositoryProvider)).call(),
    );
  }

  Future<void> verifyOtp(String code) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => VerifyOtp(ref.read(otpRepositoryProvider)).call(code),
    );
  }
}