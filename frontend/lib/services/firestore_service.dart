import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Add a transaction
  Future<void> addTransaction({
    required String userId,
    required String merchant,
    required String category,
    required int amount,
    required String paymentMethod,
  }) async {
    await _firestore.collection('transactions').add({
      'userId': userId,
      'merchant': merchant,
      'category': category,
      'amount': amount,
      'paymentMethod': paymentMethod,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // Get all transactions of a user
  Stream<QuerySnapshot> getTransactions(String userId) {
    return _firestore
        .collection('transactions')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Add an alert
  Future<void> addAlert({
    required String userId,
    required String transactionId,
    required String message,
    required String severity,
  }) async {
    await _firestore.collection('alerts').add({
      'userId': userId,
      'transactionId': transactionId,
      'message': message,
      'severity': severity,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Get alerts of a user
  Stream<QuerySnapshot> getAlerts(String userId) {
    return _firestore
        .collection('alerts')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Mark alert as read
  Future<void> markAlertAsRead(String alertId) async {
    await _firestore.collection('alerts').doc(alertId).update({
      'isRead': true,
    });
  }
}