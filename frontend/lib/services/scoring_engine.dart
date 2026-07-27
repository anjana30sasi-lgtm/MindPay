import '../models/mind_transaction.dart';

class ScoringEngine {
  static const double largeTransactionLimit = 5000;

  PauseDecision analyzeTransaction({
    required MindTransaction transaction,
    required double dailySpent,
    required double dailyLimit,
    required int categoryCount,
  }) {
    List<String> reasons = [];

    // Rule 1: Daily limit exceeded
    if (dailySpent + transaction.amount > dailyLimit) {
      reasons.add("Daily spending limit exceeded");
    }

    // Rule 2: Too many purchases in same category
    if (categoryCount >= 3) {
      reasons.add(
        "Multiple ${transaction.category} purchases today",
      );
    }

    // Rule 3: Large transaction
    if (transaction.amount >= largeTransactionLimit) {
      reasons.add("Large transaction detected");
    }

    return PauseDecision(
      reasons.isNotEmpty,
      reasons,
    );
  }
}