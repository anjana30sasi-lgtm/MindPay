import 'package:shared_preferences/shared_preferences.dart';

/// Stores onboarding answers locally so first-time setup only happens once.
/// Later, when the real backend exists, these same fields would sync to
/// Firestore instead of (or alongside) local storage.
class UserPreferencesService {
  static const _keyOnboarded = 'has_onboarded';
  static const _keyIncomeRange = 'income_range';
  static const _keySpendingStyle = 'spending_style';
  static const _keyTemptation = 'main_temptation';

  static Future<bool> hasOnboarded() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyOnboarded) ?? false;
  }

  static Future<void> saveOnboarding({
    required String incomeRange,
    required String spendingStyle,
    required String mainTemptation,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyOnboarded, true);
    await prefs.setString(_keyIncomeRange, incomeRange);
    await prefs.setString(_keySpendingStyle, spendingStyle);
    await prefs.setString(_keyTemptation, mainTemptation);
  }

  static Future<Map<String, String>> getProfile() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'incomeRange': prefs.getString(_keyIncomeRange) ?? 'Not set',
      'spendingStyle': prefs.getString(_keySpendingStyle) ?? 'Not set',
      'mainTemptation': prefs.getString(_keyTemptation) ?? 'Not set',
    };
  }

  /// Useful for demoing the onboarding flow again without reinstalling.
  static Future<void> resetOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyOnboarded, false);
  }
}
