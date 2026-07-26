# MindPay — Frontend (Flutter)

This is a working prototype of the full pause flow, running on **simulated data**,
so it's fully demoable today without waiting on the notification-reading or
backend pieces.

## How to run

```bash
flutter pub get
flutter run
```

Works on an emulator or a real phone — no backend or permissions needed yet.

## What's built

- `screens/home_screen.dart` — persona switcher (student vs professional, to
  demo income-based personalization live) + "Simulate next UPI payment" button
- `widgets/pause_dialog.dart` — the hero screen: 10-second countdown, plain-language
  reasons, Continue / Reconsider, one-tap reason tagging
- `services/scoring_engine.dart` — the rule-based logic (frequency, time-of-day,
  amount deviation) — this is the file to hand to whoever's building the "AI" part later
- `services/mock_data_service.dart` — generates realistic fake transaction history
  per persona, plus a planted demo queue (one obviously-fine transaction, two that
  should trigger a pause)
- `screens/weekly_summary_screen.dart` — the familiar Jupiter/Fi-style category
  breakdown, plus a "pause moments" card tying back to our unique feature
- `theme.dart` — the visual identity (forest teal + amber reserved only for pauses)

## Wiring in the real pieces (for whoever's doing backend/notifications)

The whole app currently talks to `MockDataService`. To go from demo to real:

1. Replace `MockDataService.generateHistory()` / `demoQueue()` with whatever the
   Notification Listener Service teammate exposes (a stream or list of
   `MindTransaction` parsed from real UPI notifications).
2. Everything downstream — `ScoringEngine`, `PauseDialog`, both screens — stays
   exactly the same, since they only depend on the `MindTransaction` model, not
   on where the data came from.
3. For Firebase: swap the in-memory `_history`/`_log` lists in `home_screen.dart`
   for Firestore reads/writes (one collection per user, e.g. `users/{uid}/transactions`).
   Model maps cleanly to a Firestore document already.

## Notes for the pitch/demo

- Tap a persona, tap "Simulate next UPI payment" three times — first one goes
  through silently, the next two trigger the pause (frequency + late-night/amount
  triggers). Switch personas and repeat to show the same logic reacting differently
  based on income.
- The reward banner ("Impulses skipped" / "Money kept") is meant to be the visual
  moment that sticks with judges.
