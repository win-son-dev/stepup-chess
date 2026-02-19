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
    return base + moveDistance(piece, from, to) * preset.distanceCost;
  }
}

/// Pure distance cost: distance * distanceCost, no base added.
///
/// Uses Chebyshev distance (max(|dx|, |dy|)) for all pieces except knights,
/// which use Manhattan distance (|dx| + |dy| = 3) to reflect the full L-shape:
///   - Pawn: 1 (one square forward)
///   - Knight: always 3 (2 + 1 squares for the L-shape)
///   - Bishop/Rook/Queen: number of squares traversed
///   - King: 1 (one square in any direction)
class DistanceCostCalculator implements CostCalculator {
  final StepCostPreset preset;

  const DistanceCostCalculator(this.preset);

  @override
  int calculate(PieceKind piece, String from, String to,
      {bool capturingKing = false}) {
    return moveDistance(piece, from, to) * preset.distanceCost;
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

/// Distance for a piece move. Knights use Manhattan distance (|dx|+|dy| = 3)
/// to reflect the full L-shape; all other pieces use Chebyshev distance.
int moveDistance(PieceKind piece, String from, String to) {
  final dx = (to.codeUnitAt(0) - from.codeUnitAt(0)).abs();
  final dy = (to.codeUnitAt(1) - from.codeUnitAt(1)).abs();
  if (piece == PieceKind.knight) return dx + dy; // always 3 for a valid L-move
  return max(dx, dy);
}
