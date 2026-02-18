import 'package:flutter/material.dart';

class MoveHistoryPanel extends StatelessWidget {
  final List<String> moves;

  const MoveHistoryPanel({super.key, required this.moves});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF8D6E63).withValues(alpha: 0.2),
        ),
      ),
      child: moves.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(4),
              child: Text(
                'No moves yet',
                style: TextStyle(
                  color: theme.colorScheme.secondary.withValues(alpha: 0.6),
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          : SizedBox(
              height: 100,
              child: SingleChildScrollView(
                reverse: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _buildRows(theme),
                ),
              ),
            ),
    );
  }

  List<Widget> _buildRows(ThemeData theme) {
    final rows = <Widget>[];
    for (var i = 0; i < moves.length; i += 2) {
      final moveNum = (i ~/ 2) + 1;
      final whiteMove = moves[i];
      final blackMove = (i + 1 < moves.length) ? moves[i + 1] : '';
      rows.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              SizedBox(
                width: 32,
                child: Text(
                  '$moveNum.',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: theme.colorScheme.outline,
                  ),
                ),
              ),
              SizedBox(
                width: 64,
                child: Text(
                  whiteMove,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              SizedBox(
                width: 64,
                child: Text(
                  blackMove,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return rows;
  }
}
