import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stepup_chess/models/game.dart';
import 'package:stepup_chess/providers/chess_provider.dart';
import 'package:stepup_chess/providers/step_provider.dart';
import 'package:stepup_chess/widgets/step_counter_display.dart';
import 'package:stepup_chess/widgets/wood_button.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(chessGameProvider);
    final hasActiveGame = gameState.status == GameStatus.active;
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.surface,
              const Color(0xFFEFE0C8),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo area with decorative border
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF3E2723),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF3E2723).withValues(alpha: 0.4),
                          offset: const Offset(0, 6),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: const Text(
                      '\u265A',
                      style: TextStyle(
                        fontSize: 64,
                        color: Color(0xFFFFF8E1),
                        height: 1.1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'StepUp Chess',
                    style: theme.textTheme.headlineLarge?.copyWith(
                      fontSize: 32,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 60,
                    height: 3,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Earn moves by walking',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Step counter in a card
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF8D6E63).withValues(alpha: 0.3),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF5D4037).withValues(alpha: 0.1),
                          offset: const Offset(0, 3),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: const StepCounterDisplay(fontSize: 32),
                  ),
                  const SizedBox(height: 40),

                  // Buttons
                  if (hasActiveGame) ...[
                    SizedBox(
                      width: double.infinity,
                      child: WoodButton.primary(
                        onPressed: () => context.go('/game'),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.play_arrow),
                            SizedBox(width: 8),
                            Text('Continue Game'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: WoodButton.secondary(
                        onPressed: () => _confirmNewGame(context, ref),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add),
                            SizedBox(width: 8),
                            Text('New Game'),
                          ],
                        ),
                      ),
                    ),
                  ] else
                    SizedBox(
                      width: double.infinity,
                      child: WoodButton.primary(
                        onPressed: () => context.go('/create'),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add),
                            SizedBox(width: 8),
                            Text('New Game'),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: WoodButton.outlined(
                      onPressed: () {
                        ref.read(stepTrackerServiceProvider).addSteps(100);
                      },
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_circle_outline),
                          SizedBox(width: 8),
                          Text('Add 100 Test Steps'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
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
            child: Text(
              'Abandon',
              style: TextStyle(color: Colors.red.shade700),
            ),
          ),
        ],
      ),
    );
  }
}
