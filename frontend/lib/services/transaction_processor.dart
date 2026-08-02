import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/transaction.dart';
import 'firestore_service.dart';
import 'scoring_engine.dart';

class TransactionProcessor {
  final FirestoreService _firestoreService = FirestoreService();
  
  Future<PauseDecision> processTransaction({
    required String userId,
    required MindTransaction transaction,
    required double dailyLimit,
  }) async {
    // Get today's transactions for this user
    List<MindTransaction> transactions =
        await _firestoreService.getTransactions(userId);

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

    // Count purchases in the same category today
    int categoryCount = transactions.where((t) {
      return t.category == transaction.category &&
          t.time.year == now.year &&
          t.time.month == now.month &&
          t.time.day == now.day;
    }).length;

    // Run scoring engine
 // Run scoring engine
PauseDecision decision = ScoringEngine.checkTransaction(
  candidate: transaction,
  history: transactions,
  dailyLimit: dailyLimit,
);
    // Update transaction status
    transaction.wasPaused = decision.shouldPause;

    if (decision.reasons.isNotEmpty) {
      transaction.reasonTag = decision.reasons.join(", ");
    }

    // Save transaction
    await _firestoreService.addTransaction(
  userId,
  transaction,
);

    // Create alert if needed
    if (decision.shouldPause) {
      await _firestoreService.addAlert(
        userId: userId,
        transactionId: transaction.id,
        message: decision.reasons.join("\n"),
        severity: "High",
      );
    }

    return decision;
  }
}