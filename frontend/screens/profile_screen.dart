import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/user_preferences_service.dart';
import 'welcome_screen.dart';
import 'onboarding_questions_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _name = '';
  String _email = '';
  double _monthlyBudget = 0;
  double _dailyLimit = 0;
  String _incomeRange = '';
  String _spendingStyle = '';
  String _temptation = '';

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await UserPreferencesService.getProfile();

    setState(() {
      _name = profile['name'];
      _email = profile['email'];
      _monthlyBudget = profile['monthlyBudget'];
      _dailyLimit = profile['dailyLimit'];
      _incomeRange = profile['incomeRange'];
      _spendingStyle = profile['spendingStyle'];
      _temptation = profile['mainTemptation'];

      _loading = false;
    });
  }

  Future<void> _logout() async {
    await UserPreferencesService.logout();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      (route) => false,
    );
  }
  Future<void> _editBudget() async {
  final controller = TextEditingController(
    text: _monthlyBudget.toStringAsFixed(0),
  );

  await showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text("Edit Monthly Budget"),
      content: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(
          labelText: "Monthly Budget",
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () async {
            final value = double.tryParse(controller.text);

            if (value != null) {
              await UserPreferencesService.updateMonthlyBudget(value);

              setState(() {
                _monthlyBudget = value;
              });
            }

            if (mounted) Navigator.pop(context);
          },
          child: const Text("Save"),
        ),
      ],
    ),
  );
}
        Future<void> _editDailyLimit() async {
  final controller = TextEditingController(
    text: _dailyLimit.toStringAsFixed(0),
  );

  await showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text("Edit Daily Limit"),
      content: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(
          labelText: "Daily Limit",
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () async {
            final value = double.tryParse(controller.text);

            if (value != null) {
              await UserPreferencesService.updateDailyLimit(value);

              setState(() {
                _dailyLimit = value;
              });
            }

            if (mounted) Navigator.pop(context);
          },
          child: const Text("Save"),
        ),
      ],
    ),
  );
}

          Future<void> _retakeOnboarding() async {
  await UserPreferencesService.resetOnboarding();

  if (!mounted) return;

  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (_) => const OnboardingQuestionsScreen(),
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: MindColors.forest,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: MindColors.background,
      appBar: AppBar(
        title: const Text("Profile"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
  padding: const EdgeInsets.all(20),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [

      Center(
        child: CircleAvatar(
          radius: 45,
          backgroundColor: MindColors.forest,
          child: Text(
            _name.isNotEmpty ? _name[0].toUpperCase() : "M",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),

      const SizedBox(height: 12),

      Center(
        child: Text(
          _name,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),

      const SizedBox(height: 4),

      Center(
        child: Text(
          _email,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),

      const SizedBox(height: 30),

      Text(
        "Financial Preferences",
        style: Theme.of(context).textTheme.headlineSmall,
      ),

      const SizedBox(height: 15),
      Card(
  elevation: 0,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(16),
    side: const BorderSide(color: MindColors.divider),
  ),
  child: Padding(
    padding: const EdgeInsets.all(18),
    child: Column(
      children: [

        Row(
          children: [
            const Icon(Icons.account_balance_wallet_outlined,
                color: MindColors.forest),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                "Monthly Budget",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            Text(
              "₹${_monthlyBudget.toStringAsFixed(0)}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                _editBudget();
              },
            ),
          ],
        ),

        const Divider(),

        Row(
          children: [
            const Icon(Icons.today_outlined,
                color: MindColors.forest),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                "Daily Limit",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            Text(
              "₹${_dailyLimit.toStringAsFixed(0)}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                _editDailyLimit();
              },
            ),
          ],
        ),

      ],
    ),
  ),
),
const SizedBox(height: 25),

Text(
  "MindPay Preferences",
  style: Theme.of(context).textTheme.headlineSmall,
),

const SizedBox(height: 15),
Card(
  elevation: 0,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(16),
    side: const BorderSide(color: MindColors.divider),
  ),
  child: Padding(
    padding: const EdgeInsets.all(18),
    child: Column(
      children: [

        Row(
          children: [
            const Icon(Icons.currency_rupee,
                color: MindColors.forest),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                "Income Range",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            Text(_incomeRange),
          ],
        ),

        const Divider(),

        Row(
          children: [
            const Icon(Icons.psychology_outlined,
                color: MindColors.forest),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                "Spending Style",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            Text(_spendingStyle),
          ],
        ),

        const Divider(),

        Row(
          children: [
            const Icon(Icons.shopping_bag_outlined,
                color: MindColors.forest),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                "Main Temptation",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            Expanded(
              child: Text(
                _temptation,
                textAlign: TextAlign.end,
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _retakeOnboarding,
            icon: const Icon(Icons.refresh),
            label: const Text("Retake Personalization"),
          ),
        ),
      ],
    ),
  ),
),
const SizedBox(height: 25),

Text(
  "Account",
  style: Theme.of(context).textTheme.headlineSmall,
),

const SizedBox(height: 15),
Card(
  elevation: 0,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(16),
    side: const BorderSide(color: MindColors.divider),
  ),
  child: Padding(
    padding: const EdgeInsets.all(18),
    child: Column(
      children: [

        ListTile(
          leading: const Icon(Icons.info_outline),
          title: const Text("MindPay"),
          subtitle: const Text("Version 1.0"),
        ),

        const Divider(),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            label: const Text("Logout"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ),

      ],
    ),
  ),
),
    ],
  ),
),
    );
  }
}