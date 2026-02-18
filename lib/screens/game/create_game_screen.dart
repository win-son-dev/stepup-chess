import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stepup_chess/config/constants.dart';
import 'package:stepup_chess/models/game.dart';
import 'package:stepup_chess/models/step_cost_preset.dart';
import 'package:stepup_chess/providers/chess_provider.dart';
import 'package:stepup_chess/widgets/step_counter_display.dart';
import 'package:stepup_chess/widgets/wood_button.dart';

class CreateGameScreen extends ConsumerStatefulWidget {
  const CreateGameScreen({super.key});

  @override
  ConsumerState<CreateGameScreen> createState() => _CreateGameScreenState();
}

class _CreateGameScreenState extends ConsumerState<CreateGameScreen> {
  int _selectedPresetIndex = 0;
  CostMode _selectedCostMode = CostMode.distance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('New Game')),
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
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Step counter in a card
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF8D6E63).withValues(alpha: 0.3),
                  ),
                ),
                child: const Center(child: StepCounterDisplay(fontSize: 22)),
              ),
              const SizedBox(height: 28),

              // Section header
              _SectionHeader(title: 'Difficulty'),
              const SizedBox(height: 12),

              ...List.generate(presets.length, (index) {
                final preset = presets[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _PresetCard(
                    preset: preset,
                    selected: _selectedPresetIndex == index,
                    onTap: () => setState(() => _selectedPresetIndex = index),
                  ),
                );
              }),
              const SizedBox(height: 20),

              _SectionHeader(title: 'Cost Mode'),
              const SizedBox(height: 12),

              // Cost mode selector as 3 tappable cards
              Row(
                children: [
                  _CostModeChip(
                    label: 'Base+Dist',
                    icon: Icons.add_circle_outline,
                    selected: _selectedCostMode == CostMode.baseDistance,
                    onTap: () =>
                        setState(() => _selectedCostMode = CostMode.baseDistance),
                  ),
                  const SizedBox(width: 8),
                  _CostModeChip(
                    label: 'Distance',
                    icon: Icons.straighten,
                    selected: _selectedCostMode == CostMode.distance,
                    onTap: () =>
                        setState(() => _selectedCostMode = CostMode.distance),
                  ),
                  const SizedBox(width: 8),
                  _CostModeChip(
                    label: 'Fixed',
                    icon: Icons.lock,
                    selected: _selectedCostMode == CostMode.fixed,
                    onTap: () =>
                        setState(() => _selectedCostMode = CostMode.fixed),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                switch (_selectedCostMode) {
                  CostMode.baseDistance => 'Piece base cost + squares moved',
                  CostMode.distance => 'Squares moved only',
                  CostMode.fixed => 'Flat cost per piece type',
                },
                style: TextStyle(
                    fontSize: 13, color: theme.colorScheme.secondary),
                textAlign: TextAlign.center,
              ),

              const Spacer(),

              // Start button
              WoodButton.primary(
                onPressed: () {
                  ref.read(chessGameProvider.notifier).startNewGame(
                        presets[_selectedPresetIndex],
                        costMode: _selectedCostMode,
                      );
                  context.go('/game');
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.play_arrow),
                    SizedBox(width: 8),
                    Text('Start Game'),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}

class _CostModeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _CostModeChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? theme.colorScheme.primary
                : const Color(0xFFFFF3E0),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected
                  ? theme.colorScheme.primary
                  : const Color(0xFF8D6E63).withValues(alpha: 0.3),
              width: selected ? 2 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      offset: const Offset(0, 3),
                      blurRadius: 6,
                    ),
                  ]
                : [],
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 20,
                color: selected
                    ? Colors.white
                    : theme.colorScheme.secondary,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: selected
                      ? Colors.white
                      : theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
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
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primaryContainer
              : const Color(0xFFFFF3E0),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? theme.colorScheme.primary
                : const Color(0xFF8D6E63).withValues(alpha: 0.2),
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.2),
                    offset: const Offset(0, 3),
                    blurRadius: 8,
                  ),
                ]
              : [
                  BoxShadow(
                    color: const Color(0xFF5D4037).withValues(alpha: 0.08),
                    offset: const Offset(0, 2),
                    blurRadius: 4,
                  ),
                ],
        ),
        child: Row(
          children: [
            // Selection indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected
                    ? theme.colorScheme.primary
                    : Colors.transparent,
                border: Border.all(
                  color: selected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline,
                  width: 2,
                ),
              ),
              child: selected
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    preset.name,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: selected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\u2659${preset.pawn}  \u2658${preset.knight}  '
                    '\u2657${preset.bishop}  \u2656${preset.rook}  '
                    '\u2655${preset.queen}  \u2654${preset.king}  '
                    '\u2194${preset.distanceCost}/sq',
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
