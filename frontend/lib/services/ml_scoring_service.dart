import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/transaction.dart';
import 'scoring_engine.dart';

/// Service to evaluate impulse spending risk using the Python FastAPI ML backend,
/// with automatic resilient fallback to the local rule-based [ScoringEngine].
///
/// Note: The predictive ML model is trained on synthetic demonstration data for
/// prototyping mindful spending nudges, and is not an empirically validated
/// clinical spending diagnostic.
class MlScoringService {
  final http.Client _client;

  MlScoringService({http.Client? client}) : _client = client ?? http.Client();

  /// Evaluates whether a candidate transaction should trigger the 10-second pause.
  ///
  /// Extracts context from the authenticated user's history, budgets, and habits,
  /// queries the FastAPI `/predict` endpoint, and returns a [PauseDecision].
  ///
  /// If the ML backend times out, is offline, or returns an error, this method
  /// seamlessly falls back to [ScoringEngine.checkTransaction].
  Future<PauseDecision> evaluateTransaction({
    required MindTransaction candidate,
    required List<MindTransaction> history,
    double? dailyLimit,
    double? monthlyBudget,
    String? spendingStyle,
    String? mainTemptation,
    String? userId,
  }) async {
    try {
      // 1. Calculate user history context
      final today = DateTime(candidate.time.year, candidate.time.month, candidate.time.day);
      final categoryHistory = history.where((t) => t.category == candidate.category).toList();

      final sameDayCount = categoryHistory
              .where((t) =>
                  t.time.year == today.year &&
                  t.time.month == today.month &&
                  t.time.day == today.day)
              .length +
          1;

      double? categoryAvg;
      if (categoryHistory.isNotEmpty) {
        categoryAvg = categoryHistory.map((t) => t.amount).reduce((a, b) => a + b) /
            categoryHistory.length;
      }

      // 2. Build payload matching TransactionPredictionRequest schema
      final Map<String, dynamic> payload = {
        'user_id': userId ?? 'authenticated_user',
        'amount': candidate.amount,
        'category': candidate.category,
        'merchant': candidate.merchant,
        'time': candidate.time.toIso8601String(),
        'daily_limit': (dailyLimit != null && dailyLimit > 0) ? dailyLimit : 5000.0,
        'monthly_budget': (monthlyBudget != null && monthlyBudget > 0) ? monthlyBudget : 40000.0,
        'spending_style': (spendingStyle != null && spendingStyle.isNotEmpty)
            ? spendingStyle
            : 'I go with the flow',
        'main_temptation': (mainTemptation != null && mainTemptation.isNotEmpty)
            ? mainTemptation
            : null,
        'same_day_category_count': sameDayCount,
        'historical_category_avg': categoryAvg,
      };

      // 3. Send request with strict timeout
      debugPrint(
        '[MlScoringService] POST ${ApiConfig.predictUrl} -> merchant="${candidate.merchant}", '
        'amount=₹${candidate.amount.toStringAsFixed(0)}, category="${candidate.category}", '
        'sameDayCount=$sameDayCount',
      );

      final response = await _client
          .post(
            Uri.parse(ApiConfig.predictUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(ApiConfig.requestTimeout);


      if (response.statusCode == 200) {
        final String responseText = utf8.decode(response.bodyBytes);
        final dynamic decoded = jsonDecode(responseText);

        if (decoded is Map<String, dynamic>) {
          final bool shouldPause = _parseBool(decoded['should_pause']) ||
              _parseBool(decoded['shouldPause']) ||
              _parseBool(decoded['is_impulsive']) ||
              _parseBool(decoded['isImpulsive']);

          final dynamic rawReasons = decoded['reasons'];
          final List<String> reasons = [];
          if (rawReasons is List) {
            for (final item in rawReasons) {
              if (item != null) {
                reasons.add(item.toString());
              }
            }
          }

          if (shouldPause && reasons.isEmpty) {
            reasons.add('Flagged as potentially impulsive spend by ML model');
          }

          debugPrint(
            '[MlScoringService] ML prediction response: shouldPause=$shouldPause, reasons=$reasons',
          );
          return PauseDecision(shouldPause, reasons);
        }
      } else {
        debugPrint(
          '[MlScoringService] Backend returned HTTP ${response.statusCode} at ${ApiConfig.predictUrl}. Falling back to rule-based engine.',
        );
      }

    } on TimeoutException {
      debugPrint('[MlScoringService] ML Backend request timed out. Falling back to rule-based engine.');
    } catch (e) {
      debugPrint('[MlScoringService] ML Backend connection error ($e). Falling back to rule-based engine.');
    }

    // Resilient fallback to deterministic local rule-based engine
    return ScoringEngine.checkTransaction(
      candidate: candidate,
      history: history,
      dailyLimit: dailyLimit,
    );
  }

  /// Checks whether the ML backend is reachable and healthy.
  Future<bool> checkHealth() async {
    try {
      final response = await _client
          .get(Uri.parse(ApiConfig.healthUrl))
          .timeout(const Duration(milliseconds: 1500));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static bool _parseBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value > 0;
    if (value is String) {
      final lower = value.trim().toLowerCase();
      return lower == 'true' || lower == '1' || lower == 'yes';
    }
    return false;
  }

  void dispose() {
    _client.close();
  }
}

