import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:mindpay_frontend/models/transaction.dart';
import 'package:mindpay_frontend/services/ml_scoring_service.dart';

void main() {
  group('MlScoringService Tests', () {
    final candidateNormal = MindTransaction(
      id: 'tx_1',
      merchant: 'BigBasket',
      category: 'Groceries',
      amount: 450.0,
      time: DateTime(2026, 10, 18, 12, 0),
    );

    final candidateSpike = MindTransaction(
      id: 'tx_2',
      merchant: 'Zomato',
      category: 'Food',
      amount: 600.0,
      time: DateTime(2026, 10, 18, 23, 30),
    );

    test('Falls back to local ScoringEngine when backend is offline or errors', () async {
      final mockClient = MockClient((request) async {
        throw http.ClientException('Connection refused');
      });

      final service = MlScoringService(client: mockClient);

      final decisionNormal = await service.evaluateTransaction(
        candidate: candidateNormal,
        history: [],
        dailyLimit: 5000.0,
      );

      expect(decisionNormal.shouldPause, isFalse);

      final decisionSpike = await service.evaluateTransaction(
        candidate: MindTransaction(
          id: 'tx_late',
          merchant: 'Food',
          category: 'Food',
          amount: 6000.0,
          time: DateTime(2026, 10, 18, 23, 45),
        ),
        history: [],
        dailyLimit: 5000.0,
      );

      expect(decisionSpike.shouldPause, isTrue);
      expect(decisionSpike.reasons.length, greaterThanOrEqualTo(2));
    });

    test('Parses ML prediction response successfully when backend responds', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, endsWith('/predict'));
        final body = jsonDecode(request.body);
        expect(body['merchant'], equals('Zomato'));

        return http.Response(
          jsonEncode({
            'should_pause': true,
            'is_impulsive': true,
            'impulse_probability': 0.82,
            'risk_level': 'HIGH',
            'reasons': [
              'Late night spend at 11:30 PM outside your usual hours',
              'High impulse confidence score (82%) detected by ML model',
            ],
            'model_version': '1.0.0-synthetic-rf',
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final service = MlScoringService(client: mockClient);

      final decision = await service.evaluateTransaction(
        candidate: candidateSpike,
        history: [],
        dailyLimit: 5000.0,
      );

      expect(decision.shouldPause, isTrue);
      expect(decision.reasons.length, equals(2));
      expect(decision.reasons.first, contains('Late night spend'));
    });

    test('Robustly coerces string, numeric, and alternative boolean fields', () async {
      // 1. String "true" for should_pause
      final mockClientString = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'should_pause': 'true',
            'reasons': ['Unusual spending spike ₹3400'],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service1 = MlScoringService(client: mockClientString);
      final decision1 = await service1.evaluateTransaction(
        candidate: candidateSpike,
        history: [],
      );
      expect(decision1.shouldPause, isTrue);
      expect(decision1.reasons.first, contains('₹3400'));

      // 2. Numeric 1 for is_impulsive with missing should_pause
      final mockClientNumeric = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'is_impulsive': 1,
            'reasons': [],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service2 = MlScoringService(client: mockClientNumeric);
      final decision2 = await service2.evaluateTransaction(
        candidate: candidateSpike,
        history: [],
      );
      expect(decision2.shouldPause, isTrue);
      // Empty reasons list gets safe default explanation
      expect(decision2.reasons, isNotEmpty);

      // 3. camelCase shouldPause: true
      final mockClientCamel = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'shouldPause': true,
            'reasons': ['CamelCase support verified'],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service3 = MlScoringService(client: mockClientCamel);
      final decision3 = await service3.evaluateTransaction(
        candidate: candidateSpike,
        history: [],
      );
      expect(decision3.shouldPause, isTrue);
      expect(decision3.reasons.first, equals('CamelCase support verified'));
    });
  });
}
