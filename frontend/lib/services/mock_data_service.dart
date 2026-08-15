import '../models/transaction.dart';

/// Simulates realistic transaction history for demo personas.
///
/// For the hackathon demo, the history is intentionally fixed so that
/// the Weekly Summary remains consistent every time the app is restarted.
///
/// In the real app, this history would instead come from the
/// Android Notification Listener Service reading real UPI notifications.
class MockDataService {
  static const _merchants = {
    'Food': ['Zomato', 'Swiggy', 'Domino\'s'],
    'Shopping': ['Amazon', 'Myntra', 'Flipkart'],
    'Travel': ['Uber', 'Ola', 'IRCTC'],
    'Groceries': ['BigBasket', 'Blinkit', 'Zepto'],
  };

  /// Generates a fixed 14-transaction history.
  ///
  /// Weekly summary:
  ///
  /// Shopping  = ₹4,988
  /// Food      = ₹4,266
  /// Groceries = ₹3,161
  /// Travel    = ₹518
  ///
  /// Total     = ₹12,933
  static List<MindTransaction> generateHistory({
    required String personaName,
    required double monthlyIncome,
  }) {
    final now = DateTime.now();

    return [
      // =========================
      // SHOPPING = ₹4,988
      // =========================

      MindTransaction(
        id: 'history_shopping_1',
        merchant: 'Amazon',
        category: 'Shopping',
        amount: 1200,
        time: now.subtract(
          const Duration(days: 1),
        ),
      ),

      MindTransaction(
        id: 'history_shopping_2',
        merchant: 'Myntra',
        category: 'Shopping',
        amount: 1100,
        time: now.subtract(
          const Duration(days: 2),
        ),
      ),

      MindTransaction(
        id: 'history_shopping_3',
        merchant: 'Flipkart',
        category: 'Shopping',
        amount: 1400,
        time: now.subtract(
          const Duration(days: 4),
        ),
      ),

      MindTransaction(
        id: 'history_shopping_4',
        merchant: 'Amazon',
        category: 'Shopping',
        amount: 1288,
        time: now.subtract(
          const Duration(days: 6),
        ),
      ),

      // =========================
      // FOOD = ₹4,266
      // =========================

      MindTransaction(
        id: 'history_food_1',
        merchant: 'Zomato',
        category: 'Food',
        amount: 1100,
        time: now.subtract(
          const Duration(days: 1),
        ),
      ),

      MindTransaction(
        id: 'history_food_2',
        merchant: 'Swiggy',
        category: 'Food',
        amount: 900,
        time: now.subtract(
          const Duration(days: 2),
        ),
      ),

      MindTransaction(
        id: 'history_food_3',
        merchant: 'Domino\'s',
        category: 'Food',
        amount: 1200,
        time: now.subtract(
          const Duration(days: 4),
        ),
      ),

      MindTransaction(
        id: 'history_food_4',
        merchant: 'Zomato',
        category: 'Food',
        amount: 1066,
        time: now.subtract(
          const Duration(days: 5),
        ),
      ),

      // =========================
      // GROCERIES = ₹3,161
      // =========================

      MindTransaction(
        id: 'history_grocery_1',
        merchant: 'BigBasket',
        category: 'Groceries',
        amount: 900,
        time: now.subtract(
          const Duration(days: 1),
        ),
      ),

      MindTransaction(
        id: 'history_grocery_2',
        merchant: 'Blinkit',
        category: 'Groceries',
        amount: 1100,
        time: now.subtract(
          const Duration(days: 3),
        ),
      ),

      MindTransaction(
        id: 'history_grocery_3',
        merchant: 'Zepto',
        category: 'Groceries',
        amount: 1161,
        time: now.subtract(
          const Duration(days: 5),
        ),
      ),

      // =========================
      // TRAVEL = ₹518
      // =========================

      MindTransaction(
        id: 'history_travel_1',
        merchant: 'Uber',
        category: 'Travel',
        amount: 200,
        time: now.subtract(
          const Duration(days: 2),
        ),
      ),

      MindTransaction(
        id: 'history_travel_2',
        merchant: 'Ola',
        category: 'Travel',
        amount: 150,
        time: now.subtract(
          const Duration(days: 4),
        ),
      ),

      MindTransaction(
        id: 'history_travel_3',
        merchant: 'Uber',
        category: 'Travel',
        amount: 168,
        time: now.subtract(
          const Duration(days: 6),
        ),
      ),
    ];
  }

  /// Demo UPI transactions.
  ///
  /// These are deliberately selected to demonstrate
  /// both normal and suspicious spending.
  static List<MindTransaction> demoQueue(
    double monthlyIncome,
  ) {
    final now = DateTime.now();

    // For a ₹45,000 monthly income:
    // baseSpend = ₹900
    //
    // This gives:
    // Normal transaction = ₹720
    // Suspicious transaction = ₹2,880

    final baseSpend = monthlyIncome * 0.02;

    return [
      // =========================================
      // DEMO 1 — NORMAL TRANSACTION
      // Should normally NOT pause
      // =========================================

      MindTransaction(
        id: 'demo_1',
        merchant: 'BigBasket',
        category: 'Groceries',
        amount: (baseSpend * 0.8).roundToDouble(),
        time: DateTime(
          now.year,
          now.month,
          now.day,
          13,
          0,
        ),
      ),

      // =========================================
      // DEMO 2 — FREQUENCY TRIGGER
      // Third food order / unusual frequency
      // =========================================

      MindTransaction(
        id: 'demo_2',
        merchant: 'Zomato',
        category: 'Food',
        amount: (baseSpend * 0.5).roundToDouble(),
        time: DateTime(
          now.year,
          now.month,
          now.day,
          22,
          10,
        ),
      ),

      // =========================================
      // DEMO 3 — HIGH RISK TRANSACTION
      //
      // For ₹45,000 income:
      // 45,000 × 0.02 = ₹900
      // 900 × 3.2 = ₹2,880
      //
      // This demonstrates:
      // - unusual time
      // - high amount
      // - crosses daily limit
      // =========================================

      MindTransaction(
        id: 'demo_3',
        merchant: 'Myntra',
        category: 'Shopping',
        amount: (baseSpend * 3.2).roundToDouble(),
        time: DateTime(
          now.year,
          now.month,
          now.day,
          1,
          15,
        ),
      ),
    ];
  }
}