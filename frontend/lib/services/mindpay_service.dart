import '../models/transaction.dart';
import 'notification_listener_service.dart';

class MindPayService {
  final NotificationListenerService _listener =
      NotificationListenerService();

  Future<void> processPaymentNotification({
    required String userId,
    required String title,
    required String body,
  }) async {
    await _listener.processNotification(
      userId: userId,
      title: title,
      body: body,
    );
  }
}