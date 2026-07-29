import 'package:flutter/material.dart';
import '../theme.dart';
import '../models/transaction.dart';
import '../services/mock_data_service.dart';
import '../services/scoring_engine.dart';
import '../services/user_preferences_service.dart';
import '../widgets/pause_dialog.dart';
import 'weekly_summary_screen.dart';
import 'welcome_screen.dart';

/// Demo personas — lets you show the same transaction triggering a pause
/// for one income tier and not another, live, in front of the mentor.
class _Persona {
  final String name;
  final double monthlyIncome;
  const _Persona(this.name, this.monthlyIncome);
}

const _personas = [
  _Persona('Aisha · Student', 15000),
  _Persona('Rahul · Working Professional', 80000),
];

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _personaIndex = 0;
  late List<MindTransaction> _history;
  late List<MindTransaction> _demoQueue;
  final List<MindTransaction> _log = [];
  int _skippedCount = 0;
  double _skippedAmount = 0;
  Map<String, String>? _profile;

  @override
  void initState() {
    super.initState();
    _loadPersona();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await UserPreferencesService.getProfile();
    if (mounted) setState(() => _profile = profile);
  }

  Future<void> _replayOnboarding() async {
    await UserPreferencesService.resetOnboarding();
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const WelcomeScreen()));
  }

  void _loadPersona() {
    final persona = _personas[_personaIndex];
    _history = MockDataService.generateHistory(
        personaName: persona.name, monthlyIncome: persona.monthlyIncome);
    _demoQueue = MockDataService.demoQueue(persona.monthlyIncome);
    _log.clear();
    _skippedCount = 0;
    _skippedAmount = 0;
  }

  void _simulateNextPayment() {
    if (_demoQueue.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No more demo transactions queued — reset persona to replay')),
      );
      return;
    }
    final tx = _demoQueue.removeAt(0);
    final decision = ScoringEngine.checkTransaction(candidate: tx, history: _history);

    if (decision.shouldPause) {
      tx.wasPaused = true;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => PauseDialog(
          transaction: tx,
          reasons: decision.reasons,
          onResolved: (continued, reasonTag) {
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
            if (!continued) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                backgroundColor: MindColors.rewardSage,
                content: Text('Nice — you just skipped an impulsive ₹${tx.amount.toStringAsFixed(0)} spend'),
              ));
            }
          },
        ),
      );
    } else {
      // Normal transaction — goes through instantly, no interruption.
      setState(() {
        _log.insert(0, tx);
        _history.add(tx);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('₹${tx.amount.toStringAsFixed(0)} to ${tx.merchant} — paid, nothing unusual')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final persona = _personas[_personaIndex];
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('MindPay', style: Theme.of(context).textTheme.headlineLarge),
                  IconButton(
                    tooltip: 'Replay onboarding (demo)',
                    icon: const Icon(Icons.replay, color: MindColors.inkSoft, size: 20),
                    onPressed: _replayOnboarding,
                  ),
                ],
              ),
              Text('Conscious spending, one pause at a time.',
                  style: Theme.of(context).textTheme.bodyMedium),
              if (_profile != null && _profile!['incomeRange'] != 'Not set') ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: MindColors.forest.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Personalized for: ${_profile!['incomeRange']} · ${_profile!['spendingStyle']} · watching ${_profile!['mainTemptation']} closely',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12),
                  ),
                ),
              ],
              const SizedBox(height: 20),

              // Persona switcher — the "different income levels" demo moment
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: MindColors.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: MindColors.divider),
                ),
                child: Row(
                  children: List.generate(_personas.length, (i) {
                    final selected = i == _personaIndex;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() {
                          _personaIndex = i;
                          _loadPersona();
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: selected ? MindColors.forest : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            _personas[i].name,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: selected ? Colors.white : MindColors.inkSoft,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 8),
              Text('Monthly income: ₹${persona.monthlyIncome.toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.bodyMedium),

              const SizedBox(height: 20),

              // Reward stat card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: MindColors.forest,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Impulses skipped',
                            style: TextStyle(color: Colors.white70, fontSize: 12)),
                        Text('$_skippedCount',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 26, fontWeight: FontWeight.w700)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Money kept', style: TextStyle(color: Colors.white70, fontSize: 12)),
                        Text('₹${_skippedAmount.toStringAsFixed(0)}',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 26, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _simulateNextPayment,
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('Simulate next UPI payment'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: MindColors.ink,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'In the real app, this fires automatically when the Notification\nListener Service detects a UPI payment notification.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 11),
              ),

              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Recent activity', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 18)),
                  TextButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(
                        builder: (_) => WeeklySummaryScreen(history: _history))),
                    child: const Text('Weekly summary →'),
                  ),
                ],
              ),
              Expanded(
                child: _log.isEmpty
                    ? Center(
                        child: Text('No transactions yet — tap the button above',
                            style: Theme.of(context).textTheme.bodyMedium))
                    : ListView.separated(
                        itemCount: _log.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) {
                          final tx = _log[i];
                          return _TransactionTile(tx: tx);
                        },
                      ),
              ),
            ],
          ),
        ),
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
                ? (tx.wasCancelled ? MindColors.rewardSage : MindColors.pauseAmber)
                : MindColors.divider,
            child: Icon(
              tx.wasPaused ? (tx.wasCancelled ? Icons.check : Icons.pause) : Icons.check_circle_outline,
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
                      ? (tx.wasCancelled ? 'Skipped after pause' : 'Continued after pause')
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
