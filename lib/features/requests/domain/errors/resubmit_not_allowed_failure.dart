import 'package:campus_lost_found/core/errors/failures.dart';
import 'package:campus_lost_found/features/requests/domain/entities/resubmit_decision.dart';

final class ResubmitNotAllowedFailure extends RequestFailure {
  final ResubmitReason reason;
  final int? attemptsRemaining;
  final DateTime? retryAfter;

  const ResubmitNotAllowedFailure({
    required this.reason,
    required String message,
    this.attemptsRemaining,
    this.retryAfter,
  }) : super(message);
}
