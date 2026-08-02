import '../models/transaction.dart';

class NotificationParser {
  MindTransaction? parse({
    required String title,
    required String body,
  }) {
    // Check if this looks like a payment notification
    if (!body.contains("₹")) {
      return null;
    }

    // Extract amount
    final RegExp amountRegex = RegExp(r'₹\s?(\d+(\.\d+)?)');
    final Match? match = amountRegex.firstMatch(body);

    if (match == null) {
      return null;
    }

    final double amount = double.parse(match.group(1)!);

    // Merchant
    String merchant = title;

    // Category
    String category = "Others";

    if (merchant.toLowerCase().contains("swiggy") ||
        merchant.toLowerCase().contains("zomato")) {
      category = "Food";
    } else if (merchant.toLowerCase().contains("uber") ||
        merchant.toLowerCase().contains("ola")) {
      category = "Travel";
    } else if (merchant.toLowerCase().contains("amazon") ||
        merchant.toLowerCase().contains("flipkart")) {
      category = "Shopping";
    }

    return MindTransaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      merchant: merchant,
      category: category,
      amount: amount,
      time: DateTime.now(),
    );
  }
}