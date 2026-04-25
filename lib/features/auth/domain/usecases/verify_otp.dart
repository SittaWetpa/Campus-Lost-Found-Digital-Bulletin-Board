import 'package:campus_lost_found/core/errors/failures.dart';
import 'package:campus_lost_found/features/auth/domain/repositories/otp_repository.dart';

class VerifyOtp {
  final OtpRepository _repository;
  const VerifyOtp(this._repository);

  Future<void> call(String code) {
    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      throw const OtpFailure('Please enter a valid 6-digit code.');
    }
    return _repository.verifyOtp(code);
  }
}