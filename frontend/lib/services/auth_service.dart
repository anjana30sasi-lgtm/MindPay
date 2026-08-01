import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==========================
  // SIGN UP
  // ==========================
  Future<User?> signUp({
    required String name,
    required String email,
    required String password,
    required int monthlyBudget,
    required int dailyLimit,
  }) async {
    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;

      if (user != null) {
        await _firestore.collection('users').doc(user.uid).set({
  'name': name,
  'email': email,
  'monthlyBudget': monthlyBudget,
  'dailyLimit': dailyLimit,

  'incomeRange': '',
  'spendingStyle': '',
  'mainTemptation': '',
  'onboarded': false,

  'createdAt': FieldValue.serverTimestamp(),
});
      }

      return user;
    } catch (e) {
      print("Signup Error: $e");
      return null;
    }
  }

  // ==========================
  // LOGIN
  // ==========================
  Future<User?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCredential =
          await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      return userCredential.user;
    } catch (e) {
      print("Login Error: $e");
      return null;
    }
  }

  // ==========================
  // SIGN OUT
  // ==========================
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // ==========================
  // CURRENT USER
  // ==========================
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // ==========================
  // USER PROFILE
  // ==========================
  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final user = _auth.currentUser;

      if (user == null) {
        print("No logged in user");
        return null;
      }

      final doc =
          await _firestore.collection('users').doc(user.uid).get();

      if (doc.exists) {
        return doc.data();
      }

      return null;
    } catch (e) {
      print("Profile Error: $e");
      return null;
    }
  }
  // ==========================
// UPDATE USER PROFILE
// ==========================
Future<void> updateUserProfile(
    Map<String, dynamic> data,
) async {
  try {
    final user = _auth.currentUser;

    if (user == null) return;

    await _firestore
        .collection('users')
        .doc(user.uid)
        .update(data);
  } catch (e) {
    print("Update Profile Error: $e");
  }
}

  // ==========================
  // SAVE TRANSACTION
  // ==========================
  Future<void> saveTransaction(
      Map<String, dynamic> transaction) async {
    try {
      final user = _auth.currentUser;

      if (user == null) {
        print("No logged in user");
        return;
      }

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('transactions')
          .add(transaction);

      print("Transaction saved successfully");
    } catch (e) {
      print("Firestore Error: $e");
    }
  }

  // ==========================
  // GET TRANSACTIONS
  // ==========================
  Future<QuerySnapshot?> getTransactions() async {
    try {
      final user = _auth.currentUser;

      if (user == null) {
        print("No logged in user");
        return null;
      }

      return await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('transactions')
          .orderBy('date', descending: true)
          .get();
    } catch (e) {
      print("Get Transactions Error: $e");
      return null;
    }
  }
  Future<void> updateMonthlyBudget(double budget) async {
  final user = _auth.currentUser;

  if (user == null) return;

  await _firestore.collection('users').doc(user.uid).update({
    'monthlyBudget': budget,
  });
}

Future<void> updateDailyLimit(double limit) async {
  final user = _auth.currentUser;

  if (user == null) return;

  await _firestore.collection('users').doc(user.uid).update({
    'dailyLimit': limit,
  });
}

  // ==========================
  // AUTH STATE
  // ==========================
  Stream<User?> authStateChanges() {
    return _auth.authStateChanges();
  }
}