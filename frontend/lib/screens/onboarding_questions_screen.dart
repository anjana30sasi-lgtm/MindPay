import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/user_preferences_service.dart';
import 'tutorial_screen.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';

/// First-time-only questions that feed personalization. This is the direct
/// answer to the "cold start" mentor question — the app isn't guessing
/// blind on day one, it has a reasonable starting point.
class OnboardingQuestionsScreen extends StatefulWidget {
  const OnboardingQuestionsScreen({super.key});
  @override
  State<OnboardingQuestionsScreen> createState() => _OnboardingQuestionsScreenState();
}

class _OnboardingQuestionsScreenState extends State<OnboardingQuestionsScreen> {
  final AuthService _authService = AuthService();
  final PageController _pageController = PageController();
  int _step = 0;

  String? _incomeRange;
  String? _spendingStyle;
  String? _mainTemptation;

  static const _incomeOptions = ['Under ₹15,000', '₹15,000–40,000', '₹40,000–80,000', 'Above ₹80,000'];
  static const _styleOptions = ['I plan ahead', 'I go with the flow', 'A bit of both'];
  static const _temptationOptions = ['Food delivery', 'Online shopping', 'Rides & travel', 'Entertainment'];

  bool get _canContinue {
    if (_step == 0) return _incomeRange != null;
    if (_step == 1) return _spendingStyle != null;
    return _mainTemptation != null;
  }

  void _next() {
    if (_step < 2) {
      setState(() => _step++);
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    } else {
      _finish();
    }
  }

 Future<void> _finish() async {
  // Keep local storage for now
  await UserPreferencesService.saveOnboarding(
    incomeRange: _incomeRange!,
    spendingStyle: _spendingStyle!,
    mainTemptation: _mainTemptation!,
  );

  // Save to Firestore
  await _authService.updateUserProfile({
    "incomeRange": _incomeRange!,
    "spendingStyle": _spendingStyle!,
    "mainTemptation": _mainTemptation!,
    "onboarded": true,
  });

  if (!mounted) return;

  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (_) => const TutorialScreen(),
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MindColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress dots
              Row(
                children: List.generate(3, (i) => Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Container(
                    width: i == _step ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i <= _step ? MindColors.forest : MindColors.divider,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                )),
              ),
              const SizedBox(height: 28),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _QuestionStep(
                      title: 'What\'s your monthly income range?',
                      subtitle: 'This helps us set spending limits that make sense for you — not the same fixed number for everyone.',
                      options: _incomeOptions,
                      selected: _incomeRange,
                      onSelect: (v) => setState(() => _incomeRange = v),
                    ),
                    _QuestionStep(
                      title: 'How would you describe your spending style?',
                      subtitle: 'No judgment here — just helps us understand your baseline.',
                      options: _styleOptions,
                      selected: _spendingStyle,
                      onSelect: (v) => setState(() => _spendingStyle = v),
                    ),
                    _QuestionStep(
                      title: 'What tempts you the most?',
                      subtitle: 'We\'ll pay closer attention here, and go easier elsewhere.',
                      options: _temptationOptions,
                      selected: _mainTemptation,
                      onSelect: (v) => setState(() => _mainTemptation = v),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MindColors.forest,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    disabledBackgroundColor: MindColors.divider,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _canContinue ? _next : null,
                  child: Text(_step < 2 ? 'Continue' : 'Finish'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuestionStep extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<String> options;
  final String? selected;
  final void Function(String) onSelect;

  const _QuestionStep({
    required this.title,
    required this.subtitle,
    required this.options,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 24),
        ...options.map((opt) {
          final isSelected = opt == selected;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GestureDetector(
              onTap: () => onSelect(opt),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
                decoration: BoxDecoration(
                  color: isSelected ? MindColors.forest.withOpacity(0.08) : MindColors.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? MindColors.forest : MindColors.divider,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(opt, style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          )),
                    ),
                    if (isSelected)
                      const Icon(Icons.check_circle, color: MindColors.forest, size: 20),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
