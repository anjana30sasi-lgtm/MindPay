import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Sign Up
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
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      return user;
    } catch (e) {
      print(e);
      return null;
    }
  }

  // Sign In
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
      print(e);
      return null;
    }
  }

  // Sign Out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Get Current User
  User? getCurrentUser() {
    return _auth.currentUser;
  }

Future<Map<String, dynamic>?> getUserProfile() async {
  try {
    final user = _auth.currentUser;

    if (user == null) return null;

    final doc =
        await _firestore.collection('users').doc(user.uid).get();

    if (doc.exists) {
      return doc.data();
    }

    return null;
  } catch (e) {
    print(e);
    return null;
  }
}
Future<void> saveTransaction(Map<String, dynamic> transaction) async {
  try {
    final user = _auth.currentUser;

    if (user == null) {
      print("No logged in user");
      return;
    }

    print("Saving transaction...");
    print(transaction);

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

Future<QuerySnapshot> getTransactions() async {
  final user = _auth.currentUser;

  return await _firestore
      .collection('users')
      .doc(user!.uid)
      .collection('transactions')
      .orderBy('date', descending: true)
      .get();

}

  // Listen for Authentication Changes
  Stream<User?> authStateChanges() {
    return _auth.authStateChanges();
  }
}