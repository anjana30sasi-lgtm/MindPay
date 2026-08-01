import 'package:flutter/material.dart';
import '../theme.dart';
import '../models/transaction.dart';
import '../services/mock_data_service.dart';
import '../services/scoring_engine.dart';
import '../services/user_preferences_service.dart';
import '../widgets/pause_dialog.dart';
import 'weekly_summary_screen.dart';
import 'welcome_screen.dart';
import '../services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mindpay_frontend/services/notification_service.dart';
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late List<MindTransaction> _history;
  late List<MindTransaction> _demoQueue;
  final List<MindTransaction> _log = [];
  final AuthService _authService = AuthService();
  int _skippedCount = 0;
  double _skippedAmount = 0;

  String _userName = '';
  String _userEmail = '';
  double _monthlyBudget = 0;
  double _dailyLimit = 0;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

 Future<void> _load() async {
  final profile = await _authService.getUserProfile();

  _userName = profile?['name'] ?? '';
  _userEmail = profile?['email'] ?? '';
  _monthlyBudget = (profile?['monthlyBudget'] ?? 0).toDouble();
  _dailyLimit = (profile?['dailyLimit'] ?? 0).toDouble();

  _history = MockDataService.generateHistory(
    personaName: _userName.isNotEmpty ? _userName : 'You',
    monthlyIncome: _monthlyBudget > 0 ? _monthlyBudget : 40000,
  );

  _demoQueue = MockDataService.demoQueue(
    _monthlyBudget > 0 ? _monthlyBudget : 40000,
  );

  final snapshot = await _authService.getTransactions();

  if (snapshot != null) {
    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;

      _log.add(
        MindTransaction(
          id: doc.id,
          userId: _authService.getCurrentUser()?.uid ?? "",
          merchant: data['merchant'] ?? '',
          category: data['category'] ?? '',
          amount: (data['amount'] ?? 0).toDouble(),
          time: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
          wasPaused: data['paused'] ?? false,
          wasCancelled: data['cancelled'] ?? false,
        ),
      );
    }
  }

  setState(() {
    _loaded = true;
  });
}

  Future<void> _replayOnboarding() async {
    await UserPreferencesService.resetOnboarding();
    if (!mounted) return;
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => const WelcomeScreen()));
  }

  Future<void> _logout() async {
    await _authService.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(context,
        MaterialPageRoute(builder: (_) => const WelcomeScreen()), (r) => false);
  }

  // MODIFIED: profile sheet for the new header avatar
  void _showProfileSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: MindColors.forest,
                      child: Text(
                        (_userName.isNotEmpty ? _userName[0] : 'M')
                            .toUpperCase(),
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _userName.isNotEmpty ? _userName : 'MindPay User',
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            _userEmail.isNotEmpty
                                ? _userEmail
                                : 'No email saved',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: MindColors.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Text('Monthly Budget',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      const Spacer(),
                      Text(
                          '₹${(_monthlyBudget > 0 ? _monthlyBudget : 40000).toStringAsFixed(0)}'),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: MindColors.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Text('Daily Spending Limit',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      const Spacer(),
                      Text(
                          '₹${(_dailyLimit > 0 ? _dailyLimit : 5000).toStringAsFixed(0)}'),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _logout,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: MindColors.ink,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(46),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Log out'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

Future<void> _onUpiNotificationReceived() async {
  if (_demoQueue.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('No more demo transactions queued for now'),
      ),
    );
    return;
  }

  final tx = _demoQueue.removeAt(0);

  final decision = ScoringEngine.checkTransaction(
    candidate: tx,
    history: _history,
    dailyLimit: _dailyLimit,
  );

  if (decision.shouldPause) {
    tx.wasPaused = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => PauseDialog(
        transaction: tx,
        reasons: decision.reasons,
        onResolved: (continued, reasonTag) async {
          Navigator.of(context).pop();

          tx.wasCancelled = !continued;
          tx.reasonTag = reasonTag;

          setState(() {
            _log.insert(0, tx);
            _history.add(tx);

            if (!continued) {
              _skippedCount++;
              _skippedAmount += tx.amount;
            }
          });

          await _authService.saveTransaction({
            'merchant': tx.merchant,
            'amount': tx.amount,
            'category': tx.category,
            'date': FieldValue.serverTimestamp(),
            'paused': true,
            'cancelled': !continued,
          });

          if (!continued) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: MindColors.rewardSage,
                content: Text(
                  'Nice — you just skipped an impulsive ₹${tx.amount.toStringAsFixed(0)} spend',
                ),
              ),
            );
          }
        },
      ),
    );
  } else {
    setState(() {
      _log.insert(0, tx);
      _history.add(tx);
    });

    await _authService.saveTransaction({
      'merchant': tx.merchant,
      'amount': tx.amount,
      'category': tx.category,
      'date': FieldValue.serverTimestamp(),
      'paused': false,
      'cancelled': false,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'UPI Payment detected: ₹${tx.amount.toStringAsFixed(0)} to ${tx.merchant}',
        ),
      ),
    );
  }
}
  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(
          body: Center(
              child: CircularProgressIndicator(color: MindColors.forest)));
    }
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // MODIFIED: refreshed header with profile avatar and updated greeting
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('MindPay',
                      style: Theme.of(context).textTheme.headlineLarge),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: _showProfileSheet,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            color: MindColors.forest,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              (_userName.isNotEmpty ? _userName[0] : 'M')
                                  .toUpperCase(),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert,
                            color: MindColors.inkSoft, size: 20),
                        onSelected: (value) {
                          if (value == 'replay') _replayOnboarding();
                          if (value == 'logout') _logout();
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem(
                              value: 'replay',
                              child: Text('Replay onboarding (demo)')),
                          PopupMenuItem(
                              value: 'logout', child: Text('Log out')),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Welcome back 👋',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: MindColors.ink,
                    ),
              ),
              Text(
                _userName.isNotEmpty ? _userName : 'MindPay User',
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(fontSize: 22),
              ),
              const SizedBox(height: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: MindColors.forest.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Monthly budget: ₹${_monthlyBudget.toStringAsFixed(0)} · Daily limit: ₹${_dailyLimit.toStringAsFixed(0)}',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontSize: 12),
                ),
              ),
              const SizedBox(height: 20),

              // MODIFIED: budget cards with a more polished two-card layout
              Row(
                children: [
                  Expanded(
                    child: _BudgetCard(
                      title: 'Monthly Budget',
                      value:
                          '₹${(_monthlyBudget > 0 ? _monthlyBudget : 40000).toStringAsFixed(0)}',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _BudgetCard(
                      title: 'Daily Limit',
                      value:
                          '₹${(_dailyLimit > 0 ? _dailyLimit : 5000).toStringAsFixed(0)}',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: MindColors.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: MindColors.divider),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.trending_up,
                            color: MindColors.forest, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          "Today's Spending",
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '₹1200 / ₹${(_dailyLimit > 0 ? _dailyLimit : 5000).toStringAsFixed(0)}',
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: ((_dailyLimit > 0 ? _dailyLimit : 5000) > 0)
                          ? (1200 / (_dailyLimit > 0 ? _dailyLimit : 5000))
                              .clamp(0.0, 1.0)
                          : 0.0,
                      backgroundColor: MindColors.divider,
                      color: MindColors.forest,
                      minHeight: 8,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // MODIFIED: slightly refined stats card spacing and alignment
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                decoration: BoxDecoration(
                  color: MindColors.forest,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Impulses skipped',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 12)),
                        Text('$_skippedCount',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Money kept',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 12)),
                        Text('₹${_skippedAmount.toStringAsFixed(0)}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              ElevatedButton.icon(
               onPressed: () async {
    await NotificationService.showFakeUpiNotification(
      merchant: "Zomato",
      amount: 250,
    );

    await Future.delayed(const Duration(seconds: 1));

    await _onUpiNotificationReceived();
  },
                icon: const Icon(Icons.notifications_active_outlined),
                label: const Text("Waiting for UPI Payment"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: MindColors.ink,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 6),
              Container(
  width: double.infinity,
  padding: const EdgeInsets.all(12),
  decoration: BoxDecoration(
    color: Colors.amber.shade50,
    borderRadius: BorderRadius.circular(10),
    border: Border.all(color: Colors.amber.shade200),
  ),
  child: Row(
    children: [
      const Icon(Icons.info_outline, color: Colors.orange),
      const SizedBox(width: 10),
      Expanded(
        child: Text(
          "Demo Mode: Tap the button to simulate receiving a UPI payment notification. "
          "In the final version this button will disappear and MindPay will automatically "
          "detect Google Pay, PhonePe, Paytm and other UPI notifications.",
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(fontSize: 12),
        ),
      ),
    ],
  ),
),

              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Recent activity',
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(fontSize: 18)),
                  TextButton(
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                WeeklySummaryScreen(history: _history))),
                    child: const Text('Weekly summary →'),
                  ),
                ],
              ),
              SizedBox(
               height: 300,
                child: _log.isEmpty
                    ? // MODIFIED: richer empty state for recent activity
                    Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.credit_card,
                                  size: 48, color: MindColors.forest),
                              const SizedBox(height: 12),
                              Text(
                                'No recent transactions',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Your spending history will appear here.\nTap the button above to experience MindPay.',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        itemCount: _log.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) => _TransactionTile(tx: _log[i]),
                      ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
    
  }
}

class _BudgetCard extends StatelessWidget {
  final String title;
  final String value;

  const _BudgetCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: MindColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: MindColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(value,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final MindTransaction tx;
  const _TransactionTile({required this.tx});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: MindColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: MindColors.divider),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: tx.wasPaused
                ? (tx.wasCancelled
                    ? MindColors.rewardSage
                    : MindColors.pauseAmber)
                : MindColors.divider,
            child: Icon(
              tx.wasPaused
                  ? (tx.wasCancelled ? Icons.check : Icons.pause)
                  : Icons.check_circle_outline,
              color: tx.wasPaused ? Colors.white : MindColors.inkSoft,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tx.merchant, style: Theme.of(context).textTheme.bodyLarge),
                Text(
                  tx.wasPaused
                      ? (tx.wasCancelled
                          ? 'Skipped after pause'
                          : 'Continued after pause')
                      : tx.category,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          Text('₹${tx.amount.toStringAsFixed(0)}',
              style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}