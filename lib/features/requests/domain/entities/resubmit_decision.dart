enum ResubmitReason {
  allowed,
  permanentBlock,
  cooldown,
  alreadyActive;

  static ResubmitReason fromString(String value) => switch (value) {
        'allowed' => ResubmitReason.allowed,
        'permanent_block' => ResubmitReason.permanentBlock,
        'cooldown' => ResubmitReason.cooldown,
        'already_active' => ResubmitReason.alreadyActive,
        _ => throw ArgumentError('Unknown ResubmitReason: $value'),
      };
}

class ResubmitDecision {
  final bool allowed;
  final ResubmitReason reason;
  final int? attemptsRemaining;
  final DateTime? retryAfter;

  const ResubmitDecision({
    required this.allowed,
    required this.reason,
    this.attemptsRemaining,
    this.retryAfter,
  });

  const ResubmitDecision.allowed({this.attemptsRemaining})
      : allowed = true,
        reason = ResubmitReason.allowed,
        retryAfter = null;

  const ResubmitDecision.permanentBlock()
      : allowed = false,
        reason = ResubmitReason.permanentBlock,
        attemptsRemaining = 0,
        retryAfter = null;

  const ResubmitDecision.cooldown(this.retryAfter)
      : allowed = false,
        reason = ResubmitReason.cooldown,
        attemptsRemaining = null;

  const ResubmitDecision.alreadyActive()
      : allowed = false,
        reason = ResubmitReason.alreadyActive,
        attemptsRemaining = null,
        retryAfter = null;
}
