abstract interface class OtpRepository {
  Future<void> sendOtp();
  Future<void> verifyOtp(String code);
}