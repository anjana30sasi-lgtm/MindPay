class MindTransaction {
  final String id;
  final String userId;
  final String merchant;
  final String category;
  final double amount;
  final DateTime time;

  bool wasPaused;
  bool wasCancelled;

  String? reasonTag;

  MindTransaction({
    required this.id,
    required this.userId,
    required this.merchant,
    required this.category,
    required this.amount,
    required this.time,
    this.wasPaused = false,
    this.wasCancelled = false,
    this.reasonTag,
  });
}

/// Result of running a transaction through the scoring engine.
class PauseDecision {
  final bool shouldPause;
  final List<String> reasons;

  PauseDecision(this.shouldPause, this.reasons);
}