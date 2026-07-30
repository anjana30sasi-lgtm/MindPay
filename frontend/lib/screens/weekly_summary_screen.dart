import 'package:flutter/material.dart';
import '../theme.dart';
import '../models/transaction.dart';


/// The "familiar" feature — like Jupiter/Fi/Walnut's end-of-week breakdown.
/// This isn't the unique pitch, but it makes the app feel complete.
class WeeklySummaryScreen extends StatelessWidget {
  final List<MindTransaction> history;
  const WeeklySummaryScreen({super.key, required this.history});

  @override
  Widget build(BuildContext context) {
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    final recent = history.where((t) => t.time.isAfter(weekAgo)).toList();

    final Map<String, double> byCategory = {};
    for (final t in recent) {
      byCategory[t.category] = (byCategory[t.category] ?? 0) + t.amount;
    }
    final total = byCategory.values.fold(0.0, (a, b) => a + b);
    final sorted = byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final colors = [
      MindColors.forest,
      MindColors.forestLight,
      MindColors.rewardSage,
      MindColors.pauseAmber,
    ];

    final skipped = recent.where((t) => t.wasCancelled).toList();
    final skippedTotal = skipped.fold(0.0, (a, b) => a + b.amount);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: MindColors.background,
        elevation: 0,
        title: const Text('This week'),
        foregroundColor: MindColors.ink,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('₹${total.toStringAsFixed(0)}', style: Theme.of(context).textTheme.headlineLarge),
            Text('spent across ${recent.length} transactions', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 20),

            // Simple stacked bar — category breakdown
            if (total > 0)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  height: 14,
                  child: Row(
                    children: sorted.asMap().entries.map((e) {
                      final flex = (e.value.value / total * 1000).round().clamp(1, 1000);
                      return Expanded(
                        flex: flex,
                        child: Container(color: colors[e.key % colors.length]),
                      );
                    }).toList(),
                  ),
                ),
              ),
            const SizedBox(height: 16),

            ...sorted.asMap().entries.map((e) {
              final pct = total > 0 ? (e.value.value / total * 100) : 0;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 10, height: 10,
                      decoration: BoxDecoration(
                        color: colors[e.key % colors.length],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(e.value.key, style: Theme.of(context).textTheme.bodyLarge)),
                    Text('₹${e.value.value.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(width: 8),
                    Text('${pct.toStringAsFixed(0)}%', style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              );
            }),

            const SizedBox(height: 24),
            // The differentiator, surfaced here too — trigger insight
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: MindColors.forest.withOpacity(0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: MindColors.forest.withOpacity(0.15)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Your pause moments', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 16)),
                  const SizedBox(height: 6),
                  Text(
                    skipped.isEmpty
                        ? 'No impulsive spends caught this week — nice and steady.'
                        : 'You skipped ${skipped.length} impulsive spends this week, keeping ₹${skippedTotal.toStringAsFixed(0)} in your pocket.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
