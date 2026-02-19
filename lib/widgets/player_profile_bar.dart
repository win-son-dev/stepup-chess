import 'package:flutter/material.dart';

/// Displays a player profile row (avatar, name, captured pieces) styled like
/// chess.com — opponent sits above the board, the local player below it.
class PlayerProfileBar extends StatelessWidget {
  final String name;

  /// `true` = white player; `false` = black player.
  final bool isWhite;

  /// Current board FEN, used to derive which pieces have been captured.
  final String fen;

  /// Optional widget shown on the trailing edge (e.g. step counter).
  final Widget? trailing;

  const PlayerProfileBar({
    super.key,
    required this.name,
    required this.isWhite,
    required this.fen,
    this.trailing,
  });

  // Captured piece ordering by value (descending).
  static const _pieceOrder = ['q', 'r', 'b', 'n', 'p', 'k'];

  static const _unicodeMap = {
    'K': '♔', 'Q': '♕', 'R': '♖', 'B': '♗', 'N': '♘', 'P': '♙',
    'k': '♚', 'q': '♛', 'r': '♜', 'b': '♝', 'n': '♞', 'p': '♟',
  };

  // Returns FEN piece chars for what THIS player has captured from the opponent.
  List<String> _capturedPieces() {
    final boardPart = fen.split(' ').first;
    final Map<String, int> counts = {};
    for (final ch in boardPart.split('')) {
      if (RegExp(r'[rnbqkpRNBQKP]').hasMatch(ch)) {
        counts[ch] = (counts[ch] ?? 0) + 1;
      }
    }

    // White player shows missing BLACK pieces (what white took).
    // Black player shows missing WHITE pieces (what black took).
    final initial = isWhite
        ? <String, int>{'q': 1, 'r': 2, 'b': 2, 'n': 2, 'p': 8, 'k': 1}
        : <String, int>{'Q': 1, 'R': 2, 'B': 2, 'N': 2, 'P': 8, 'K': 1};

    final result = <String>[];
    for (final piece in _pieceOrder) {
      final key = isWhite ? piece : piece.toUpperCase();
      final missing = (initial[key] ?? 0) - (counts[key] ?? 0);
      for (var i = 0; i < missing; i++) {
        result.add(key);
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final captured = _capturedPieces();
    final theme = Theme.of(context);

    final avatarBg = isWhite ? Colors.white : const Color(0xFF1E1E1E);
    final avatarFg = isWhite ? Colors.black87 : Colors.white;
    final avatarBorderColor =
        isWhite ? const Color(0xFFBDBDBD) : const Color(0xFF424242);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      child: Row(
        children: [
          // Avatar circle
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: avatarBg,
              border: Border.all(color: avatarBorderColor, width: 2),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                isWhite ? '♔' : '♚',
                style: TextStyle(fontSize: 22, color: avatarFg),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Name + captured pieces
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                if (captured.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    captured.map((p) => _unicodeMap[p] ?? '').join(''),
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.onSurface,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ],
            ),
          ),

          ?trailing,
        ],
      ),
    );
  }
}