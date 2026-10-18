import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:mindpay_frontend/models/transaction.dart';
import 'package:mindpay_frontend/services/ml_scoring_service.dart';
import 'package:mindpay_frontend/widgets/pause_dialog.dart';

void main() {
  testWidgets('Triggering a transaction with shouldPause=true displays PauseDialog', (tester) async {
    final mockClient = MockClient((request) async {
      return http.Response(
        jsonEncode({
          'should_pause': true,
          'is_impulsive': true,
          'impulse_probability': 0.9881,
          'risk_level': 'HIGH',
          'reasons': [
            'Late night spend at 01:15 AM outside your usual hours',
            'Amount is 3.1x higher than your usual shopping spend',
          ],
        }),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    });

    final mlService = MlScoringService(client: mockClient);

    final tx = MindTransaction(
      id: 'demo_high_risk',
      merchant: 'Myntra',
      category: 'Shopping',
      amount: 2880.0,
      time: DateTime(2026, 10, 18, 1, 15),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                final decision = await mlService.evaluateTransaction(
                  candidate: tx,
                  history: [],
                  dailyLimit: 5000.0,
                );

                if (decision.shouldPause) {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) => PauseDialog(
                      transaction: tx,
                      reasons: decision.reasons,
                      onResolved: (continued, reasonTag) {},
                    ),
                  );
                }
              },
              child: const Text('Simulate UPI Payment'),
            ),
          ),
        ),
      ),
    );

    // Tap button to simulate UPI payment
    await tester.tap(find.text('Simulate UPI Payment'));
    await tester.pumpAndSettle();

    // Verify PauseDialog is shown
    expect(find.byType(PauseDialog), findsOneWidget);
    expect(find.text('Just a moment'), findsOneWidget);
    expect(find.text('₹2880 to Myntra'), findsOneWidget);
    expect(find.text('Late night spend at 01:15 AM outside your usual hours'), findsOneWidget);
  });
}
