import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindpay_frontend/models/transaction.dart';
import 'package:mindpay_frontend/widgets/pause_dialog.dart';

void main() {
  testWidgets('PauseDialog displays transaction details and reasons', (tester) async {
    final tx = MindTransaction(
      id: 'test_tx',
      merchant: 'Myntra',
      category: 'Shopping',
      amount: 3400.0,
      time: DateTime.now(),
    );

    final reasons = [
      'Late night spend at 01:15 AM outside your usual hours',
      'High impulse confidence score (96%) detected by ML model',
    ];

    bool resolved = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => PauseDialog(
                    transaction: tx,
                    reasons: reasons,
                    onResolved: (continued, reasonTag) {
                      resolved = true;
                    },
                  ),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    // Tap open
    await tester.tap(find.text('Open'));
    await tester.pump();

    // Verify PauseDialog is shown
    expect(find.byType(PauseDialog), findsOneWidget);
    expect(find.text('Just a moment'), findsOneWidget);
    expect(find.text('₹3400 to Myntra'), findsOneWidget);
    expect(find.text(reasons[0]), findsOneWidget);
    expect(find.text(reasons[1]), findsOneWidget);
    expect(find.text('Continue Payment'), findsOneWidget);
    expect(find.text('Reconsider'), findsOneWidget);
  });
}
