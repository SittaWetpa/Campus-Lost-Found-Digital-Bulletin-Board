import 'package:cloud_functions/cloud_functions.dart';
import 'package:campus_lost_found/core/errors/failures.dart';

abstract interface class OtpRemoteDatasource {
  Future<void> sendOtp();
  Future<void> verifyOtp(String code);
}

class CloudFunctionOtpDatasource implements OtpRemoteDatasource {
  final FirebaseFunctions _functions;
  const CloudFunctionOtpDatasource(this._functions);

  @override
  Future<void> sendOtp() async {
    try {
      await _functions.httpsCallable('sendOtp').call();
    } on FirebaseFunctionsException catch (e) {
      throw OtpFailure(e.message ?? 'Failed to send OTP.');
    }
  }

  @override
  Future<void> verifyOtp(String code) async {
    try {
      await _functions.httpsCallable('verifyOtp').call({'code': code});
    } on FirebaseFunctionsException catch (e) {
      throw OtpFailure(e.message ?? 'OTP verification failed.');
    }
  }
}