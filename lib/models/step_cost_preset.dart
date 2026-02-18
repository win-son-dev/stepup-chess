import 'package:chess/chess.dart' as chess;

class StepCostPreset {
  final String name;
  final int pawn;
  final int knight;
  final int bishop;
  final int rook;
  final int queen;
  final int king;

  const StepCostPreset({
    required this.name,
    required this.pawn,
    required this.knight,
    required this.bishop,
    required this.rook,
    required this.queen,
    required this.king,
  });

  int costFor(chess.PieceType type)
  {
    switch (type) {
      case chess.PieceType.PAWN:
        return pawn;
      case chess.PieceType.KNIGHT:
        return knight;
      case chess.PieceType.BISHOP:
        return bishop;
      case chess.PieceType.ROOK:
        return rook;
      case chess.PieceType.QUEEN:
        return queen;
      case chess.PieceType.KING:
        return king;
      default:
        return 0;
    }
  }
}
