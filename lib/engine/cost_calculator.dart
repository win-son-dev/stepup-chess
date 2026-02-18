import 'dart:math';
import 'package:stepup_chess/engine/piece.dart';
import 'package:stepup_chess/models/step_cost_preset.dart';

/// Strategy interface for calculating the step cost of a chess move.
abstract class CostCalculator {
  /// Calculate the step cost for moving [piece] from [from] to [to].
  /// [capturingKing] is true when the move captures the opponent's king.
  int calculate(PieceKind piece, String from, String to,
      {bool capturingKing = false});
}

/// Base + distance cost: preset base cost + distance * distanceCost.
class BaseDistanceCostCalculator implements CostCalculator {
  final StepCostPreset preset;

  const BaseDistanceCostCalculator(this.preset);

  @override
  int calculate(PieceKind piece, String from, String to,
      {bool capturingKing = false}) {
    final base = preset.costFor(piece);
    return base + chebyshevDistance(from, to) * preset.distanceCost;
  }
}

/// Pure distance cost: distance * distanceCost, no base added.
///
/// Chebyshev distance = max(|dx|, |dy|) — the number of king-moves between
/// two squares. This naturally maps to how far a piece actually travels:
///   - Pawn: 1 (one square forward)
///   - Knight: always 2 (L-shape fits in a 2×2 Chebyshev box)
///   - Bishop/Rook/Queen: number of squares traversed
///   - King: 1 (one square in any direction)
class DistanceCostCalculator implements CostCalculator {
  final StepCostPreset preset;

  const DistanceCostCalculator(this.preset);

  @override
  int calculate(PieceKind piece, String from, String to,
      {bool capturingKing = false}) {
    return chebyshevDistance(from, to) * preset.distanceCost;
  }
}

/// Fixed cost — flat cost per piece type, ignoring distance.
/// King captures cost double.
class FixedCostCalculator implements CostCalculator {
  final StepCostPreset preset;

  const FixedCostCalculator(this.preset);

  @override
  int calculate(PieceKind piece, String from, String to,
      {bool capturingKing = false}) {
    final base = preset.costFor(piece);
    return capturingKing ? base * 2 : base;
  }
}

/// Chebyshev distance between two algebraic squares (e.g. "e2", "e4").
int chebyshevDistance(String from, String to) {
  final dx = (to.codeUnitAt(0) - from.codeUnitAt(0)).abs();
  final dy = (to.codeUnitAt(1) - from.codeUnitAt(1)).abs();
  return max(dx, dy);
}
