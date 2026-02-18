import 'package:stepup_chess/engine/piece.dart';

class StepCostPreset {
  final String name;
  final int pawn;
  final int knight;
  final int bishop;
  final int rook;
  final int queen;
  final int king;

  /// Steps per square moved. Scales distance cost to match the preset's difficulty.
  final int distanceCost;

  const StepCostPreset({
    required this.name,
    required this.pawn,
    required this.knight,
    required this.bishop,
    required this.rook,
    required this.queen,
    required this.king,
    this.distanceCost = 1,
  });

  int costFor(PieceKind kind) {
    switch (kind) {
      case PieceKind.pawn:
        return pawn;
      case PieceKind.knight:
        return knight;
      case PieceKind.bishop:
        return bishop;
      case PieceKind.rook:
        return rook;
      case PieceKind.queen:
        return queen;
      case PieceKind.king:
        return king;
    }
  }
}
