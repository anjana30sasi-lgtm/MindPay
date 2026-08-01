import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/transaction.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Add a transaction
  Future<void> addTransaction(
    String userId,
    MindTransaction transaction,
) async {
  await _firestore
      .collection('users')
      .doc(userId)
      .collection('transactions')
      .doc(transaction.id)
      .set({
      //'userId': transaction.userId,
      'merchant': transaction.merchant,
      'category': transaction.category,
      'amount': transaction.amount,
      'time': transaction.time,
      'wasPaused': transaction.wasPaused,
      'wasCancelled': transaction.wasCancelled,
      'reasonTag': transaction.reasonTag,
    });
  }

  // Get all transactions of a user
  Future<List<MindTransaction>> getTransactions(String userId) async {
    QuerySnapshot snapshot = await _firestore
    .collection('users')
    .doc(userId)
    .collection('transactions')
    .orderBy('time', descending: true)
    .get();

    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;

      return MindTransaction(
        id: doc.id,
       // userId: data['userId'],
        merchant: data['merchant'],
        category: data['category'],
        amount: (data['amount'] as num).toDouble(),
        time: (data['time'] as Timestamp).toDate(),
        wasPaused: data['wasPaused'] ?? false,
        wasCancelled: data['wasCancelled'] ?? false,
        reasonTag: data['reasonTag'],
      );
    }).toList();
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

  // Delete a transaction
  Future<void> deleteTransaction(
    String userId,
    String transactionId,
) async {
  await _firestore
      .collection('users')
      .doc(userId)
      .collection('transactions')
      .doc(transactionId)
      .delete();
}

  // Delete an alert
  Future<void> deleteAlert(String alertId) async {
    await _firestore.collection('alerts').doc(alertId).delete();
  }
}