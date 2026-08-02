import '../models/transaction.dart';
import 'notification_parser.dart';
import 'transaction_processor.dart';
import 'budget_service.dart';

class NotificationListenerService {
  final NotificationParser _parser = NotificationParser();
  final TransactionProcessor _processor = TransactionProcessor();
  final BudgetService _budgetService = BudgetService();

  Future<void> processNotification({
    required String userId,
    required String title,
    required String body,
  }) async {
    // Convert notification into a transaction
    MindTransaction? transaction = _parser.parse(
      title: title,
      body: body,
    );

    // Ignore if not a payment notification
    if (transaction == null) {
      return;
    }

    // Get user's daily limit
    double dailyLimit = await _budgetService.getDailyLimit(userId);

    // Process transaction
    await _processor.processTransaction(
  userId: userId,
  transaction: transaction,
  dailyLimit: dailyLimit,
);
  }
}