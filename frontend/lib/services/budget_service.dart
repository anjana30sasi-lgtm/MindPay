import 'package:cloud_firestore/cloud_firestore.dart';

class BudgetService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get daily budget
  Future<double> getDailyLimit(String userId) async {
    DocumentSnapshot doc =
        await _firestore.collection('users').doc(userId).get();

    if (!doc.exists) {
      return 0;
    }

    final data = doc.data() as Map<String, dynamic>;

    return (data['dailyLimit'] as num?)?.toDouble() ?? 0;
  }

  // Get monthly budget
  Future<double> getMonthlyBudget(String userId) async {
    DocumentSnapshot doc =
        await _firestore.collection('users').doc(userId).get();

    if (!doc.exists) {
      return 0;
    }

    final data = doc.data() as Map<String, dynamic>;

    return (data['monthlyBudget'] as num?)?.toDouble() ?? 0;
  }

  // Update daily budget
  Future<void> updateDailyLimit(
      String userId, double dailyLimit) async {
    await _firestore.collection('users').doc(userId).update({
      'dailyLimit': dailyLimit,
    });
  }

  // Update monthly budget
  Future<void> updateMonthlyBudget(
      String userId, double monthlyBudget) async {
    await _firestore.collection('users').doc(userId).update({
      'monthlyBudget': monthlyBudget,
    });
  }
}