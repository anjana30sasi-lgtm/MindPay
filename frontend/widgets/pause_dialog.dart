import 'dart:async';
import 'package:flutter/material.dart';
import '../theme.dart';
import '../models/transaction.dart';

/// The hero screen of the whole app. Shows for up to 10 seconds when a
/// transaction is flagged as unusual. User can act immediately (both
/// buttons stay enabled the whole time — this is a nudge, not a lock).
class PauseDialog extends StatefulWidget {
  final MindTransaction transaction;
  final List<String> reasons;
  final void Function(bool continued, String? reasonTag) onResolved;

  const PauseDialog({
    super.key,
    required this.transaction,
    required this.reasons,
    required this.onResolved,
  });

  @override
  State<PauseDialog> createState() => _PauseDialogState();
}

class _PauseDialogState extends State<PauseDialog> {
  int _secondsLeft = 10;
  Timer? _timer;
  bool _decided = false;

  @override
  @override
void initState() {
  super.initState();

  _timer = Timer.periodic(const Duration(seconds: 1), (t) {
    if (!mounted) return;

    setState(() {
      _secondsLeft--;
    });

    if (_secondsLeft == 0) {
      t.cancel();

      if (!_decided) {
        _resolve(true, null); // Auto continue after 10 seconds
      }
    }
  });
}

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _resolve(bool continued, String? reasonTag) {
  if (_decided) return;

  _decided = true;
  _timer?.cancel();

  Navigator.of(context).pop(); // Close dialog immediately

  widget.onResolved(continued, reasonTag);
}

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: MindColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Countdown ring
            SizedBox(
              width: 56,
              height: 56,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: _secondsLeft / 10,
                    strokeWidth: 4,
                    backgroundColor: MindColors.divider,
                    valueColor: const AlwaysStoppedAnimation(MindColors.pauseAmber),
                  ),
                  Text('$_secondsLeft', style: const TextStyle(
                      fontWeight: FontWeight.w700, color: MindColors.ink, fontSize: 16)),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text('Just a moment',
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 6),
            Text(
              '₹${widget.transaction.amount.toStringAsFixed(0)} to ${widget.transaction.merchant}',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 14),
            // Plain-language reasons — this is what makes it feel human, not judgmental
            ...widget.reasons.map((r) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      const Icon(Icons.circle, size: 5, color: MindColors.pauseAmber),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text(r, style: Theme.of(context).textTheme.bodyMedium)),
                    ],
                  ),
                )),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: MindColors.forest,
                      side: const BorderSide(color: MindColors.forest),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => _resolve(true, null),
                    child: const Text('Continue Payment'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: MindColors.rewardSage,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => _showReasonSheet(context, continued: false),
                    child: const Text('Reconsider'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showReasonSheet(BuildContext context, {required bool continued}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: MindColors.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        const tags = [
  'Too expensive',
  'Impulse purchase',
  'Can wait',
  'Didnt need it',
];;
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('What made you reconsider?',
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 4),
              Text('Your feedback helps MindPay reduce future impulse spending.',
                  style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: tags
                    .map((tag) => ActionChip(
                          label: Text(tag),
                          backgroundColor: MindColors.background,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: const BorderSide(color: MindColors.divider),
                          ),
                          onPressed: () {
                            Navigator.pop(ctx);
                            _resolve(continued, tag);
                          },
                        ))
                    .toList(),
              ),
            ],
          ),
        );
      },
    );
  }
}
