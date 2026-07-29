import 'package:shared_preferences/shared_preferences.dart';

class UserPreferencesService {
  // ------------------------------
  // Keys
  // ------------------------------

  static const _keyLoggedIn = 'is_logged_in';
  static const _keyOnboarded = 'has_onboarded';

  static const _keyUserId = 'user_id';
  static const _keyUserName = 'user_name';
  static const _keyEmail = 'user_email';
  static const _keyMonthlyBudget = 'monthly_budget';
  static const _keyDailyLimit = 'daily_limit';

  static const _keyIncomeRange = 'income_range';
  static const _keySpendingStyle = 'spending_style';
  static const _keyTemptation = 'main_temptation';

  // ------------------------------
  // Login
  // ------------------------------

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyLoggedIn) ?? false;
  }

  static Future<void> login({
    required String name,
    required String email,
    String userId = '',
    double monthlyBudget = 0,
    double dailyLimit = 0,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(_keyLoggedIn, true);
    await prefs.setString(_keyUserName, name);
    await prefs.setString(_keyEmail, email);
    await prefs.setString(_keyUserId, userId);
    await prefs.setDouble(_keyMonthlyBudget, monthlyBudget);
    await prefs.setDouble(_keyDailyLimit, dailyLimit);
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(_keyLoggedIn, false);
  }

  // ------------------------------
  // User Details
  // ------------------------------

  static Future<String> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserId) ?? '';
  }

  static Future<String> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserName) ?? '';
  }

  static Future<String> getEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyEmail) ?? '';
  }

  static Future<double> getMonthlyBudget() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_keyMonthlyBudget) ?? 0;
  }

  static Future<double> getDailyLimit() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_keyDailyLimit) ?? 0;
  }

  // ------------------------------
  // Complete User Profile
  // ------------------------------

  static Future<Map<String, dynamic>> getProfile() async {
    final prefs = await SharedPreferences.getInstance();

    return {
      'userId': prefs.getString(_keyUserId) ?? '',
      'name': prefs.getString(_keyUserName) ?? '',
      'email': prefs.getString(_keyEmail) ?? '',
      'monthlyBudget': prefs.getDouble(_keyMonthlyBudget) ?? 0,
      'dailyLimit': prefs.getDouble(_keyDailyLimit) ?? 0,
      'incomeRange': prefs.getString(_keyIncomeRange) ?? 'Not set',
      'spendingStyle': prefs.getString(_keySpendingStyle) ?? 'Not set',
      'mainTemptation': prefs.getString(_keyTemptation) ?? 'Not set',
    };
  }

  // ------------------------------
  // Onboarding
  // ------------------------------

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

  // ------------------------------
  // Reset
  // ------------------------------

  static Future<void> resetOnboarding() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(_keyOnboarded, false);

    await prefs.remove(_keyIncomeRange);
    await prefs.remove(_keySpendingStyle);
    await prefs.remove(_keyTemptation);
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}