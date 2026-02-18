import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stepup_chess/providers/step_provider.dart';

class StepCounterDisplay extends ConsumerWidget {
  final double fontSize;

  const StepCounterDisplay({super.key, this.fontSize = 28});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stepBag = ref.watch(stepBagProvider);
    final theme = Theme.of(context);

    return stepBag.when(
      data: (steps) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.directions_walk,
              size: fontSize, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              '$steps',
              key: ValueKey(steps),
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            'steps',
            style: TextStyle(
              fontSize: fontSize * 0.5,
              color: theme.colorScheme.secondary,
            ),
          ),
        ],
      ),
      loading: () => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.directions_walk,
              size: fontSize, color: theme.colorScheme.outline),
          const SizedBox(width: 8),
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ],
      ),
      error: (_, _) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.directions_walk, size: fontSize, color: Colors.red),
          const SizedBox(width: 8),
          Text(
            '${ref.read(stepTrackerServiceProvider).stepBag}',
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
