import 'package:campus_lost_found/features/auth/domain/repositories/otp_repository.dart';

class SendOtp {
  final OtpRepository _repository;
  const SendOtp(this._repository);

  Future<void> call() => _repository.sendOtp();
}