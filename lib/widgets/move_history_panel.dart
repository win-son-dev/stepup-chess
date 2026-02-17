import 'package:flutter/material.dart';

class MoveHistoryPanel extends StatelessWidget {
  final List<String> moves;

  const MoveHistoryPanel({super.key, required this.moves});

  @override
  Widget build(BuildContext context) {
    if (moves.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(8.0),
        child: Text(
          'No moves yet',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    // Pair moves into (white, black) rows
    final rows = <Widget>[];
    for (var i = 0; i < moves.length; i += 2) {
      final moveNum = (i ~/ 2) + 1;
      final whiteMove = moves[i];
      final blackMove = (i + 1 < moves.length) ? moves[i + 1] : '';
      rows.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          child: Row(
            children: [
              SizedBox(
                width: 32,
                child: Text(
                  '$moveNum.',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ),
              SizedBox(
                width: 60,
                child: Text(whiteMove, style: const TextStyle(fontWeight: FontWeight.w500)),
              ),
              SizedBox(
                width: 60,
                child: Text(blackMove, style: const TextStyle(fontWeight: FontWeight.w500)),
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: 120,
      child: SingleChildScrollView(
        reverse: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: rows,
        ),
      ),
    );
  }
}
