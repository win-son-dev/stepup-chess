import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stepup_chess/config/constants.dart';
import 'package:stepup_chess/models/step_cost_preset.dart';
import 'package:stepup_chess/providers/chess_provider.dart';
import 'package:stepup_chess/widgets/step_counter_display.dart';

class CreateGameScreen extends ConsumerStatefulWidget {
  const CreateGameScreen({super.key});

  @override
  ConsumerState<CreateGameScreen> createState() => _CreateGameScreenState();
}

class _CreateGameScreenState extends ConsumerState<CreateGameScreen> {
  int _selectedPresetIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Game')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const StepCounterDisplay(fontSize: 22),
            const SizedBox(height: 32),
            const Text(
              'Choose Difficulty',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...List.generate(presets.length, (index) {
              final preset = presets[index];
              return _PresetCard(
                preset: preset,
                selected: _selectedPresetIndex == index,
                onTap: () => setState(() => _selectedPresetIndex = index),
              );
            }),
            const Spacer(),
            FilledButton.icon(
              onPressed: () {
                ref
                    .read(chessGameProvider.notifier)
                    .startNewGame(presets[_selectedPresetIndex]);
                context.go('/game');
              },
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start Game', style: TextStyle(fontSize: 18)),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PresetCard extends StatelessWidget {
  final StepCostPreset preset;
  final bool selected;
  final VoidCallback onTap;

  const _PresetCard({
    required this.preset,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: selected ? 4 : 1,
      color: selected ? Colors.green.shade50 : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selected ? Colors.green : Colors.grey.shade300,
          width: selected ? 2 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                preset.name,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: selected ? Colors.green.shade800 : null,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Pawn: ${preset.pawn}  Knight: ${preset.knight}  '
                'Bishop: ${preset.bishop}  Rook: ${preset.rook}  '
                'Queen: ${preset.queen}  King: ${preset.king}',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
