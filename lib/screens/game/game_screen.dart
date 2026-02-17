import 'package:flutter/material.dart';
import 'package:flutter_chess_board/flutter_chess_board.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stepup_chess/providers/chess_provider.dart';
import 'package:stepup_chess/providers/step_provider.dart';
import 'package:stepup_chess/models/game.dart';
import 'package:stepup_chess/widgets/step_counter_display.dart';
import 'package:stepup_chess/widgets/piece_cost_legend.dart';
import 'package:stepup_chess/widgets/move_history_panel.dart';
import 'package:stepup_chess/widgets/stepup_chess_board.dart';

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  late ChessBoardController _boardController;

  @override
  void initState() {
    super.initState();
    _boardController = ChessBoardController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chessGameProvider.notifier).attachBoardController(_boardController);
    });
  }

  void _onMove() {
    final notifier = ref.read(chessGameProvider.notifier);
    final success = notifier.validateAndChargeLastMove();

    if (!success) {
      _showCantAffordSnackbar();
      return;
    }

    // Check if either king is in check after this move
    final checkedSide = notifier.getCheckedSide();
    if (checkedSide != null) {
      _showCheckSnackbar(checkedSide);
    }
  }

  bool _onKingCapture({
    required String from,
    required String to,
    required PieceType attackerType,
    required Color capturedKingColor,
  }) {
    final notifier = ref.read(chessGameProvider.notifier);
    final success = notifier.handleKingCapture(
      from: from,
      to: to,
      attackerType: attackerType,
      capturedKingColor: capturedKingColor,
    );

    if (!success) {
      _showCantAffordSnackbar(isKingCapture: true);
      return false;
    }

    // Show game over
    final winner = capturedKingColor == Color.WHITE ? 'Black' : 'White';
    _showGameEndDialog(GameStatus.kingCaptured, winner: winner);
    return true;
  }

  void _showCheckSnackbar(String checkedSide) {
    final color = checkedSide == 'white' ? 'White' : 'Black';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$color king is in check!'),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showCantAffordSnackbar({bool isKingCapture = false}) {
    final msg = isKingCapture
        ? 'Not enough steps! King capture costs DOUBLE.'
        : 'Not enough steps! Keep walking to earn more.';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showGameEndDialog(GameStatus status, {String? winner}) {
    String title;
    String message;

    switch (status) {
      case GameStatus.kingCaptured:
        title = 'King Captured!';
        message = '${winner ?? "Someone"} wins by capturing the king!';
        break;
      case GameStatus.resigned:
        title = 'Resigned';
        message = 'Game over by resignation.';
        break;
      default:
        return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Back to Home'),
          ),
        ],
      ),
    );
  }

  void _onResign() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Resign?'),
        content: const Text('Are you sure you want to resign?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(chessGameProvider.notifier).resign();
              _showGameEndDialog(GameStatus.resigned);
            },
            child: const Text('Resign', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _addTestSteps() {
    ref.read(stepTrackerServiceProvider).addSteps(100);
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(chessGameProvider);
    final stepBag = ref.watch(stepBagProvider);
    final currentSteps =
        stepBag.value ?? ref.read(stepTrackerServiceProvider).stepBag;

    return Scaffold(
      appBar: AppBar(
        title: const Text('StepUp Chess'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Add 100 test steps',
            onPressed: _addTestSteps,
          ),
          IconButton(
            icon: const Icon(Icons.flag),
            tooltip: 'Resign',
            onPressed: gameState.status == GameStatus.active ? _onResign : null,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Step counter
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: StepCounterDisplay(fontSize: 24),
            ),

            // Chess board
            Expanded(
              child: Center(
                child: StepUpChessBoard(
                  controller: _boardController,
                  boardColor: BoardColor.brown,
                  enableUserMoves: gameState.status == GameStatus.active,
                  onMove: _onMove,
                  onKingCapture: _onKingCapture,
                ),
              ),
            ),

            // Piece cost legend
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: PieceCostLegend(
                preset: gameState.preset,
                availableSteps: currentSteps,
              ),
            ),

            // Move history
            MoveHistoryPanel(moves: gameState.moveHistory),
          ],
        ),
      ),
    );
  }
}
