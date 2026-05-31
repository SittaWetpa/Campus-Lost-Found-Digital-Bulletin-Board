import 'package:campus_lost_found/features/auth/data/datasources/otp_remote_datasource.dart';
import 'package:campus_lost_found/features/auth/domain/repositories/otp_repository.dart';

class OtpRepositoryImpl implements OtpRepository {
  final OtpRemoteDatasource _datasource;
  const OtpRepositoryImpl(this._datasource);

  @override
  Future<void> sendOtp() => _datasource.sendOtp();

  @override
  Future<void> verifyOtp(String code) => _datasource.verifyOtp(code);
}