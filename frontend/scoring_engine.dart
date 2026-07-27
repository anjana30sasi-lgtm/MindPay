import '../models/transaction.dart';

/// Simple, explainable rule-based engine — matches what we pitched to the
/// mentor: no black-box AI, every pause has a plain-language reason.
///
/// This is the ONLY file the "AI/logic" teammate needs to swap out later
/// if they want to plug in a smarter model — the interface (checkTransaction)
/// stays the same.
class ScoringEngine {
  /// Number of points needed before we trigger the pause popup.
  static const int pauseThreshold = 2;

  static PauseDecision checkTransaction({
    required MindTransaction candidate,
    required List<MindTransaction> history,
  }) {
    int score = 0;
    final List<String> reasons = [];

    // Only look at this category's history for fair comparisons.
    final categoryHistory =
        history.where((t) => t.category == candidate.category).toList();

    // --- Rule 1: Frequency spike (same category, same day) ---
    final today = DateTime(candidate.time.year, candidate.time.month, candidate.time.day);
    final sameDayCount = categoryHistory
            .where((t) =>
                t.time.year == today.year &&
                t.time.month == today.month &&
                t.time.day == today.day)
            .length +
        1; // +1 to include the candidate itself
    if (sameDayCount >= 3) {
      score += 1;
      reasons.add('This is your ${_ordinal(sameDayCount)} ${candidate.category.toLowerCase()} order today');
    }

    // --- Rule 2: Time-of-day anomaly (late night / very early) ---
    if (candidate.time.hour >= 23 || candidate.time.hour <= 4) {
      score += 1;
      reasons.add('This is outside your usual spending hours');
    }

    // --- Rule 3: Amount deviation from personal average for this category ---
    if (categoryHistory.isNotEmpty) {
      final avg = categoryHistory.map((t) => t.amount).reduce((a, b) => a + b) /
          categoryHistory.length;
      if (candidate.amount > avg * 2) {
        score += 1;
        final multiple = (candidate.amount / avg).toStringAsFixed(1);
        reasons.add('This is ${multiple}x your usual ${candidate.category.toLowerCase()} spend');
      }
    }

    return PauseDecision(score >= pauseThreshold, reasons);
  }

  static String _ordinal(int n) {
    if (n == 1) return '1st';
    if (n == 2) return '2nd';
    if (n == 3) return '3rd';
    return '${n}th';
  }
}
