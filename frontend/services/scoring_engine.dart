import '../models/transaction.dart';

/// Simple, explainable rule-based engine — matches what we pitched to the
/// mentor: no black-box AI, every pause has a plain-language reason.
class ScoringEngine {
  static const int pauseThreshold = 2;

  static PauseDecision checkTransaction({
    required MindTransaction candidate,
    required List<MindTransaction> history,
    double? dailyLimit,
  }) {
    int score = 0;
    final List<String> reasons = [];

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
        1;
    if (sameDayCount >= 3) {
      score += 1;
      reasons.add('This is your ${_ordinal(sameDayCount)} ${candidate.category.toLowerCase()} order today');
    }

    // --- Rule 2: Time-of-day anomaly ---
    if (candidate.time.hour >= 23 || candidate.time.hour <= 4) {
      score += 1;
      reasons.add('This is outside your usual spending hours');
    }

    // --- Rule 3: Amount deviation from personal average ---
    if (categoryHistory.isNotEmpty) {
      final avg = categoryHistory.map((t) => t.amount).reduce((a, b) => a + b) /
          categoryHistory.length;
      if (candidate.amount > avg * 2) {
        score += 1;
        final multiple = (candidate.amount / avg).toStringAsFixed(1);
        reasons.add('This is ${multiple}x your usual ${candidate.category.toLowerCase()} spend');
      }
    }

    // --- Rule 4: Daily limit crossed (uses the value set at onboarding) ---
    if (dailyLimit != null && dailyLimit > 0) {
      final todaySpend = history
              .where((t) =>
                  t.time.year == today.year &&
                  t.time.month == today.month &&
                  t.time.day == today.day)
              .fold(0.0, (sum, t) => sum + t.amount) +
          candidate.amount;
      if (todaySpend > dailyLimit) {
        score += 1;
        reasons.add('This crosses your daily limit of ₹${dailyLimit.toStringAsFixed(0)}');
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