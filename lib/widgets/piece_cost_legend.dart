import 'package:flutter/material.dart';
import 'package:stepup_chess/models/step_cost_preset.dart';

class PieceCostLegend extends StatelessWidget {
  final StepCostPreset preset;
  final int availableSteps;

  const PieceCostLegend({
    super.key,
    required this.preset,
    required this.availableSteps,
  });

  @override
  Widget build(BuildContext context) {
    final pieces = [
      _PieceCostItem('King', '\u2654', preset.king),
      _PieceCostItem('Queen', '\u2655', preset.queen),
      _PieceCostItem('Rook', '\u2656', preset.rook),
      _PieceCostItem('Bishop', '\u2657', preset.bishop),
      _PieceCostItem('Knight', '\u2658', preset.knight),
      _PieceCostItem('Pawn', '\u2659', preset.pawn),
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 4,
      children: pieces.map((item) {
        final canAfford = availableSteps >= item.cost;
        return Chip(
          avatar: Text(item.symbol, style: const TextStyle(fontSize: 18)),
          label: Text(
            '${item.cost}',
            style: TextStyle(
              color: canAfford ? Colors.black : Colors.red,
              fontWeight: canAfford ? FontWeight.normal : FontWeight.bold,
            ),
          ),
          backgroundColor: canAfford
              ? Colors.green.shade50
              : Colors.red.shade50,
          side: BorderSide(
            color: canAfford ? Colors.green.shade200 : Colors.red.shade200,
          ),
        );
      }).toList(),
    );
  }
}

class _PieceCostItem {
  final String name;
  final String symbol;
  final int cost;

  _PieceCostItem(this.name, this.symbol, this.cost);
}
