import 'package:flutter/material.dart';
import '../theme.dart';
import 'home_screen.dart';

class _TutorialCard {
  final IconData icon;
  final String title;
  final String description;

  const _TutorialCard({
    required this.icon,
    required this.title,
    required this.description,
  });
}

const _cards = [
  _TutorialCard(
    icon: Icons.visibility_outlined,
    title: 'We quietly watch your spending',
    description:
        'MindPay learns your normal habits over time — no extra effort from you.',
  ),
  _TutorialCard(
    icon: Icons.pause_circle_outline,
    title: 'When something looks unusual, we pause',
    description:
        'A gentle 10-second check-in appears — only for spending that\'s out of the ordinary for you.',
  ),
  _TutorialCard(
    icon: Icons.check_circle_outline,
    title: 'You\'re always in control',
    description:
        'Continue if you meant to spend it, or reconsider if you didn\'t. Either way, no judgment.',
  ),
];

class TutorialScreen extends StatefulWidget {
  const TutorialScreen({super.key});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  final PageController _controller = PageController();

  int _page = 0;

  void _goHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const HomeScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _page == _cards.length - 1;

    return Scaffold(
      backgroundColor: MindColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: TextButton(
                  onPressed: _goHome,
                  child: Text(
                    'Skip',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _cards.length,
                onPageChanged: (i) {
                  setState(() {
                    _page = i;
                  });
                },
                itemBuilder: (context, i) {
                  final card = _cards[i];

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            color: MindColors.forest.withOpacity(0.08),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            card.icon,
                            size: 44,
                            color: MindColors.forest,
                          ),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          card.title,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          card.description,
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(
                                color: MindColors.inkSoft,
                              ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _cards.length,
                (i) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: i == _page ? 20 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: i == _page
                        ? MindColors.forest
                        : MindColors.divider,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MindColors.forest,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: isLast
                      ? _goHome
                      : () {
                          _controller.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOut,
                          );
                        },
                  child: Text(
                    isLast ? 'Start using MindPay' : 'Next',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}