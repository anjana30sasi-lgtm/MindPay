import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/transaction.dart';
import 'firestore_service.dart';
import 'scoring_engine.dart';

class TransactionProcessor {
  final FirestoreService _firestoreService = FirestoreService();
  final ScoringEngine _scoringEngine = ScoringEngine();

  Future<PauseDecision> processTransaction({
    required MindTransaction transaction,
    required double dailyLimit,
  }) async {
    // Get today's transactions
    List<MindTransaction> transactions =
        await _firestoreService.getTransactions(transaction.userId);

    DateTime now = DateTime.now();

    // Calculate today's spending
    double dailySpent = 0;

    for (var t in transactions) {
      if (t.time.year == now.year &&
          t.time.month == now.month &&
          t.time.day == now.day) {
        dailySpent += t.amount;
      }
    }

    // Count purchases in same category today
    int categoryCount = transactions.where((t) {
      return t.category == transaction.category &&
          t.time.year == now.year &&
          t.time.month == now.month &&
          t.time.day == now.day;
    }).length;

    // Run scoring engine
    PauseDecision decision = _scoringEngine.analyzeTransaction(
      transaction: transaction,
      dailySpent: dailySpent,
      dailyLimit: dailyLimit,
      categoryCount: categoryCount,
    );

    // Update transaction
    transaction.wasPaused = decision.shouldPause;

    if (decision.reasons.isNotEmpty) {
      transaction.reasonTag = decision.reasons.join(", ");
    }

    // Save transaction
    await _firestoreService.addTransaction(transaction);

    // Create alert if needed
    if (decision.shouldPause) {
      await _firestoreService.addAlert(
        userId: transaction.userId,
        transactionId: transaction.id,
        message: decision.reasons.join("\n"),
        severity: "High",
      );
    }

    return decision;
  }
}