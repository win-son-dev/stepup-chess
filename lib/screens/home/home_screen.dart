import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stepup_chess/models/game.dart';
import 'package:stepup_chess/providers/chess_provider.dart';
import 'package:stepup_chess/providers/step_provider.dart';
import 'package:stepup_chess/widgets/step_counter_display.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(chessGameProvider);
    final hasActiveGame = gameState.status == GameStatus.active;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.directions_walk,
                  size: 80,
                  color: Colors.green,
                ),
                const SizedBox(height: 16),
                Text(
                  'StepUp Chess',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Earn moves by walking',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                ),
                const SizedBox(height: 48),
                const StepCounterDisplay(fontSize: 32),
                const SizedBox(height: 48),
                if (hasActiveGame) ...[
                  FilledButton.icon(
                    onPressed: () => context.go('/game'),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text(
                      'Continue Game',
                      style: TextStyle(fontSize: 18),
                    ),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () => _confirmNewGame(context, ref),
                    icon: const Icon(Icons.add),
                    label: const Text(
                      'New Game',
                      style: TextStyle(fontSize: 18),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                  ),
                ] else
                  FilledButton.icon(
                    onPressed: () => context.go('/create'),
                    icon: const Icon(Icons.add),
                    label: const Text(
                      'New Game',
                      style: TextStyle(fontSize: 18),
                    ),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: () {
                    ref.read(stepTrackerServiceProvider).addSteps(100);
                  },
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('Add 100 Test Steps'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmNewGame(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Abandon Game?'),
        content: const Text(
          'You have a game in progress. Starting a new game will abandon it.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(chessGameProvider.notifier).clearGame();
              context.go('/create');
            },
            child: const Text(
              'Abandon',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
