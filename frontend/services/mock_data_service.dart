import 'dart:math';
import '../models/transaction.dart';

/// Simulates realistic transaction history for demo personas.
/// In the real app, this history would instead come from the
/// Android Notification Listener Service reading real UPI notifications.
class MockDataService {
  static final _rand = Random();

  static const _merchants = {
    'Food': ['Zomato', 'Swiggy', 'Domino\'s'],
    'Shopping': ['Amazon', 'Myntra', 'Flipkart'],
    'Travel': ['Uber', 'Ola', 'IRCTC'],
    'Groceries': ['BigBasket', 'Blinkit', 'Zepto'],
  };

  /// Generates 30 days of history for a persona.
  /// [monthlyIncome] drives what counts as a "normal" amount for that user.
  static List<MindTransaction> generateHistory({
    required String personaName,
    required double monthlyIncome,
  }) {
    final List<MindTransaction> history = [];
    final baseSpend = monthlyIncome * 0.02; // ~2% of income = typical single spend
    final now = DateTime.now();

    for (int day = 30; day >= 1; day--) {
      final date = now.subtract(Duration(days: day));
      final txCountToday = _rand.nextInt(3) + 1; // 1-3 normal transactions/day

      for (int t = 0; t < txCountToday; t++) {
        final category = _merchants.keys.elementAt(_rand.nextInt(_merchants.length));
        final merchant = _merchants[category]![_rand.nextInt(_merchants[category]!.length)];
        final amount = (baseSpend * (0.5 + _rand.nextDouble())).roundToDouble();
        final hour = 9 + _rand.nextInt(12); // normal daytime hours

        history.add(MindTransaction(
          id: 'tx_${day}_$t',
          merchant: merchant,
          category: category,
          amount: amount,
          time: DateTime(date.year, date.month, date.day, hour, _rand.nextInt(60)),
        ));
      }
    }
    return history;
  }

  /// A few "live" transactions to trigger during the demo — deliberately
  /// planted so at least one clearly fires the pause and one clearly doesn't.
  static List<MindTransaction> demoQueue(double monthlyIncome) {
    final baseSpend = monthlyIncome * 0.02;
    final now = DateTime.now();
    return [
      // Normal — should NOT pause
      MindTransaction(
        id: 'demo_1',
        merchant: 'BigBasket',
        category: 'Groceries',
        amount: (baseSpend * 0.8).roundToDouble(),
        time: DateTime(now.year, now.month, now.day, 13, 0),
      ),
      // 3rd food order today — frequency trigger
      MindTransaction(
        id: 'demo_2',
        merchant: 'Zomato',
        category: 'Food',
        amount: (baseSpend * 0.5).roundToDouble(),
        time: DateTime(now.year, now.month, now.day, 22, 10),
      ),
      // Late night + high amount — time + amount trigger
      MindTransaction(
        id: 'demo_3',
        merchant: 'Myntra',
        category: 'Shopping',
        amount: (baseSpend * 3.2).roundToDouble(),
        time: DateTime(now.year, now.month, now.day, 1, 15),
      ),
    ];
  }
}
