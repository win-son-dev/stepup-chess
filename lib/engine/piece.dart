/// Unified piece types for StepUp Chess — no dependency on chess packages.
enum PieceKind { pawn, knight, bishop, rook, queen, king }

enum PieceColor { white, black }

class BoardPiece {
  final PieceKind kind;
  final PieceColor color;

  const BoardPiece(this.kind, this.color);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BoardPiece && kind == other.kind && color == other.color;

  @override
  int get hashCode => Object.hash(kind, color);

  @override
  String toString() => 'BoardPiece($kind, $color)';
}
