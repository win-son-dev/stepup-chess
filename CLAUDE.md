# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

StepUp Chess is a Flutter app that gamifies chess by tying piece movement costs to real-world step counts. Every chess move costs "steps" earned by walking, tracked via the device pedometer. The app uses a "step bag" currency system that persists across app restarts.

## Common Commands

- **Run:** `flutter run` (use `-d macos`, `-d chrome`, `-d ios`, etc. to target a specific platform)
- **Test:** `flutter test` (run single test: `flutter test test/widget_test.dart`)
- **Analyze/Lint:** `flutter analyze`
- **Format:** `dart format .`
- **Get dependencies:** `flutter pub get`

## Architecture

### State Management: Riverpod

All state flows through Riverpod providers in `lib/providers/`:

- **`chessGameProvider`** (`NotifierProvider<ChessGameNotifier, GameState>`) — holds chess game state, move validation, step cost deduction. The notifier bridges Riverpod with `ChessBoardController` (a `ValueNotifier<Chess>` from `flutter_chess_board`), attached at runtime via `attachBoardController()` in `GameScreen.initState`.
- **`stepBagProvider`** (`StreamProvider<int>`) — exposes the current step balance as a stream.
- **`stepTrackerServiceProvider`** (`Provider<StepTrackerService>`) — pedometer integration, step persistence, and the step bag broadcast stream.
- **`sharedPreferencesProvider`** (`Provider<SharedPreferences>`) — initialized async in `main()` and overridden at the root `ProviderScope`.

### Routing: GoRouter

Flat route table in `lib/config/routes.dart`:
- `/` → `HomeScreen` — step display + new game button
- `/create` → `CreateGameScreen` — preset selection
- `/game` → `GameScreen` — active game board

Navigation uses `context.go('/route')`.

### Key Design Decisions

- **King capture is custom:** The `chess` engine forbids king capture, so `StepUpChessBoard` intercepts drag-drop onto king squares, validates move geometry manually, then directly manipulates the board FEN via `handleKingCapture()`.
- **Turn enforcement removed:** `_alignTurn()` swaps the active color in the FEN before any move, allowing either player to move at any time ("free play" mechanic).
- **Step costs doubled for king captures** via `getCost(..., capturingKing: true)`.
- **Pedometer reboot handling:** `StepTrackerService` uses a baseline/last-known-steps approach stored in `SharedPreferences` to survive app and device restarts.
- **Debug affordance:** Both `HomeScreen` and `GameScreen` have an "Add 100 Test Steps" button that calls `StepTrackerService.addSteps(100)`.

### Code Layout

- `models/` — Data classes with `copyWith` (`GameState`, `StepCostPreset`)
- `providers/` — Riverpod providers separated by concern (chess vs. steps)
- `services/` — Business logic and platform integration (`StepTrackerService`)
- `screens/` — UI organized by feature (`home/`, `game/`)
- `widgets/` — Shared UI components (board, step counter, move history, piece cost legend)
- `config/` — Constants (SharedPreferences keys, preset definitions) and router

### Platform Notes

All six Flutter platforms are scaffolded. The pedometer (`pedometer_2`) requires native sensor access and works on iOS/Android. On desktop/web, step tracking may need mocking or the debug "Add Steps" button.

### Dependencies

Key packages: `chess` (engine), `flutter_chess_board` (board widget, heavily customized), `pedometer_2` (step tracking), `flutter_riverpod` (state), `go_router` (routing), `shared_preferences` (persistence).

SDK constraint: Dart `^3.10.1`. Linting: `package:flutter_lints/flutter.yaml` with defaults.
