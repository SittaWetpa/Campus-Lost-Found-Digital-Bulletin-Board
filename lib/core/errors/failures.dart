sealed class Failure implements Exception {
  final String message;
  const Failure(this.message);
}

final class InvalidDomainFailure extends Failure {
  const InvalidDomainFailure()
      : super('Only @mail.kmutt.ac.th emails are allowed.');
}

final class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

final class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

final class NetworkFailure extends Failure {
  const NetworkFailure() : super('No internet connection.');
}

final class OtpFailure extends Failure {
  const OtpFailure(super.message);
}

final class ItemFailure extends Failure {
  const ItemFailure(super.message);
}

final class ProfileFailure extends Failure {
  const ProfileFailure(super.message);
}

base class RequestFailure extends Failure {
  const RequestFailure(super.message);
}