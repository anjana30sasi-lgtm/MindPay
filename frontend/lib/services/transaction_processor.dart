import '../models/transaction.dart';
import 'firestore_service.dart';
import 'ml_scoring_service.dart';

class TransactionProcessor {
  final FirestoreService _firestoreService = FirestoreService();
  final MlScoringService _mlScoringService = MlScoringService();
  
  Future<PauseDecision> processTransaction({
    required String userId,
    required MindTransaction transaction,
    required double dailyLimit,
    double? monthlyBudget,
    String? spendingStyle,
    String? mainTemptation,
  }) async {
    // Get transactions for this user from Firestore
    List<MindTransaction> transactions =
        await _firestoreService.getTransactions(userId);

    // Run ML scoring engine with automatic rule-based fallback

    PauseDecision decision = await _mlScoringService.evaluateTransaction(
      candidate: transaction,
      history: transactions,
      dailyLimit: dailyLimit,
      monthlyBudget: monthlyBudget,
      spendingStyle: spendingStyle,
      mainTemptation: mainTemptation,
      userId: userId,
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