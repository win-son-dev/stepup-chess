import 'package:flutter/material.dart';
import 'package:flutter_chess_board/flutter_chess_board.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stepup_chess/engine/piece.dart';
import 'package:stepup_chess/providers/chess_provider.dart';
import 'package:stepup_chess/providers/step_provider.dart';
import 'package:stepup_chess/models/game.dart';
import 'package:stepup_chess/widgets/move_history_panel.dart';
import 'package:stepup_chess/widgets/player_profile_bar.dart';
import 'package:stepup_chess/widgets/speed_display.dart';
import 'package:stepup_chess/widgets/step_counter_display.dart';
import 'package:stepup_chess/widgets/stepup_chess_board.dart';

// ---------------------------------------------------------------------------
// Chat message model (session-only, not persisted)
// ---------------------------------------------------------------------------

class _ChatMessage {
  final String sender; // 'White' or 'Black'
  final String text;
  final DateTime time;

  _ChatMessage({required this.sender, required this.text, required this.time});
}

// ---------------------------------------------------------------------------
// Game Screen
// ---------------------------------------------------------------------------

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  late ChessBoardController _boardController;
  final List<_ChatMessage> _chatMessages = [];

  @override
  void initState() {
    super.initState();
    _boardController = ChessBoardController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chessGameProvider.notifier).attachBoardController(_boardController);
    });
  }

  // ---------------------------------------------------------------------------
  // Board callbacks
  // ---------------------------------------------------------------------------

  bool _canAfford(PieceKind piece, String from, String to) {
    final notifier = ref.read(chessGameProvider.notifier);
    final affordable = notifier.canAffordMove(piece, from, to);
    if (!affordable) _showCantAffordSnackbar();
    return affordable;
  }

  void _onChargeMove(PieceKind piece, String from, String to) {
    ref.read(chessGameProvider.notifier).chargeAndRecordMove(piece, from, to);
  }

  int _getCost(PieceKind piece, String from, String to,
      {bool capturingKing = false}) {
    return ref.read(chessGameProvider.notifier).moveCost(piece, from, to,
        capturingKing: capturingKing);
  }

  void _onMove() {}

  bool _onKingCapture({
    required String from,
    required String to,
    required PieceKind attackerKind,
    required PieceColor capturedKingColor,
  }) {
    final success = ref.read(chessGameProvider.notifier).handleKingCapture(
          from: from,
          to: to,
          attackerKind: attackerKind,
          capturedKingColor: capturedKingColor,
        );

    if (!success) {
      _showCantAffordSnackbar(isKingCapture: true);
      return false;
    }

    final winner = capturedKingColor == PieceColor.white ? 'Black' : 'White';
    _showGameEndDialog(GameStatus.kingCaptured, winner: winner);
    return true;
  }

  // ---------------------------------------------------------------------------
  // Snackbars & dialogs
  // ---------------------------------------------------------------------------

  void _showCantAffordSnackbar({bool isKingCapture = false}) {
    final msg = isKingCapture
        ? 'Not enough steps for king capture!'
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
      case GameStatus.draw:
        title = 'Draw';
        message = 'The game ended in a draw.';
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
              ref.read(chessGameProvider.notifier).clearGame();
              context.go('/');
            },
            child: const Text('Back to Home'),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // More options bottom sheet
  // ---------------------------------------------------------------------------

  void _showMoreSheet() {
    final gameState = ref.read(chessGameProvider);
    final isActive = gameState.status == GameStatus.active;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            if (isActive) ...[
              ListTile(
                leading: const Icon(Icons.flag, color: Colors.red),
                title: const Text('Resign'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _confirmResign();
                },
              ),
              ListTile(
                leading: const Icon(Icons.handshake_outlined, color: Colors.blue),
                title: const Text('Offer Draw'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _confirmDraw();
                },
              ),
              const Divider(),
            ],
            ListTile(
              leading: const Icon(Icons.add_circle_outline),
              title: const Text('Add 100 test steps'),
              onTap: () {
                Navigator.of(ctx).pop();
                ref.read(stepTrackerServiceProvider).addSteps(100);
              },
            ),
            ListTile(
              leading: const Icon(Icons.sports_esports_outlined),
              title: const Text('New Game'),
              onTap: () {
                Navigator.of(ctx).pop();
                context.go('/create');
              },
            ),
            ListTile(
              leading: const Icon(Icons.home_outlined),
              title: const Text('Back to Home'),
              onTap: () {
                Navigator.of(ctx).pop();
                context.go('/');
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _confirmResign() {
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

  void _confirmDraw() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Offer Draw?'),
        content: const Text('Both players agree to end the game as a draw?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(chessGameProvider.notifier).offerDraw();
              _showGameEndDialog(GameStatus.draw);
            },
            child: const Text('Agree'),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Chat bottom sheet
  // ---------------------------------------------------------------------------

  void _showChatSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _ChatSheet(
        messages: _chatMessages,
        onSend: (sender, text) {
          setState(() {
            _chatMessages.add(_ChatMessage(
              sender: sender,
              text: text,
              time: DateTime.now(),
            ));
          });
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String _costModeLabel(CostMode mode) {
    return switch (mode) {
      CostMode.baseDistance => 'Base+Dist',
      CostMode.distance => 'Distance',
      CostMode.fixed => 'Fixed',
    };
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(chessGameProvider);
    final notifier = ref.read(chessGameProvider.notifier);
    final isActive = gameState.status == GameStatus.active;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('StepUp Chess'),
            Text(
              '${gameState.preset.name} \u2022 ${_costModeLabel(gameState.costMode)}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          if (gameState.isReviewing)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Chip(
                label: Text(
                  'Move ${gameState.historyIndex} / ${gameState.fenHistory.length - 1}',
                  style: const TextStyle(fontSize: 12),
                ),
                backgroundColor: Colors.amber.shade100,
                visualDensity: VisualDensity.compact,
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Opponent profile (Black)
            PlayerProfileBar(
              name: 'Black',
              isWhite: false,
              fen: gameState.fen,
              trailing: const SpeedDisplay(speed: 0, size: 44),
            ),

            // Chess board
            Expanded(
              child: Center(
                child: StepUpChessBoard(
                  engine: notifier.engine,
                  controller: _boardController,
                  boardColor: BoardColor.green,
                  enableUserMoves: isActive && !gameState.isReviewing,
                  lastMove: gameState.lastMove,
                  canAfford: _canAfford,
                  onChargeMove: _onChargeMove,
                  getCost: _getCost,
                  onMove: _onMove,
                  onKingCapture: _onKingCapture,
                ),
              ),
            ),

            // Player profile (White)
            PlayerProfileBar(
              name: 'White',
              isWhite: true,
              fen: gameState.fen,
              trailing: const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  StepCounterDisplay(fontSize: 16),
                  SizedBox(height: 2),
                  SpeedDisplay(speed: 0, size: 40),
                ],
              ),
            ),

            // Move history
            MoveHistoryPanel(moves: gameState.moveHistory),
          ],
        ),
      ),

      // Bottom navigation bar
      bottomNavigationBar: _GameBottomBar(
        canGoBack: gameState.historyIndex > 0,
        canGoForward: gameState.isReviewing,
        hasUnreadChat: false,
        onPrevious: () => ref.read(chessGameProvider.notifier).stepBack(),
        onNext: () => ref.read(chessGameProvider.notifier).stepForward(),
        onChat: _showChatSheet,
        onMore: _showMoreSheet,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom bar widget
// ---------------------------------------------------------------------------

class _GameBottomBar extends StatelessWidget {
  final bool canGoBack;
  final bool canGoForward;
  final bool hasUnreadChat;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onChat;
  final VoidCallback onMore;

  const _GameBottomBar({
    required this.canGoBack,
    required this.canGoForward,
    required this.hasUnreadChat,
    required this.onPrevious,
    required this.onNext,
    required this.onChat,
    required this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      height: 60,
      padding: EdgeInsets.zero,
      child: Row(
        children: [
          Expanded(
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new),
              tooltip: 'Previous position',
              onPressed: canGoBack ? onPrevious : null,
            ),
          ),
          Expanded(
            child: IconButton(
              icon: const Icon(Icons.arrow_forward_ios),
              tooltip: 'Next position',
              onPressed: canGoForward ? onNext : null,
            ),
          ),
          Expanded(
            child: Badge(
              isLabelVisible: hasUnreadChat,
              child: IconButton(
                icon: const Icon(Icons.chat_bubble_outline),
                tooltip: 'Chat',
                onPressed: onChat,
              ),
            ),
          ),
          Expanded(
            child: IconButton(
              icon: const Icon(Icons.more_horiz),
              tooltip: 'More options',
              onPressed: onMore,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Chat sheet widget
// ---------------------------------------------------------------------------

class _ChatSheet extends StatefulWidget {
  final List<_ChatMessage> messages;
  final void Function(String sender, String text) onSend;

  const _ChatSheet({required this.messages, required this.onSend});

  @override
  State<_ChatSheet> createState() => _ChatSheetState();
}

class _ChatSheetState extends State<_ChatSheet> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  String _activeSender = 'White';

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onSend(_activeSender, text);
    _controller.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SizedBox(
        height: 420,
        child: Column(
          children: [
            // Handle + title
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Chat',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Divider(height: 16),

            // Messages
            Expanded(
              child: widget.messages.isEmpty
                  ? const Center(
                      child: Text(
                        'No messages yet',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: widget.messages.length,
                      itemBuilder: (ctx, i) {
                        final msg = widget.messages[i];
                        final isWhite = msg.sender == 'White';
                        return Align(
                          alignment: isWhite
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 3),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isWhite
                                  ? Colors.green.shade100
                                  : Colors.grey.shade200,
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(12),
                                topRight: const Radius.circular(12),
                                bottomLeft: Radius.circular(isWhite ? 12 : 0),
                                bottomRight: Radius.circular(isWhite ? 0 : 12),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: isWhite
                                  ? CrossAxisAlignment.end
                                  : CrossAxisAlignment.start,
                              children: [
                                Text(
                                  msg.sender,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(msg.text),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),

            const Divider(height: 1),

            // Sender toggle + input
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
              child: Row(
                children: [
                  // Sender toggle
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'White', label: Text('W')),
                      ButtonSegment(value: 'Black', label: Text('B')),
                    ],
                    selected: {_activeSender},
                    onSelectionChanged: (val) =>
                        setState(() => _activeSender = val.first),
                    style: ButtonStyle(
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: 'Type a message…',
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        isDense: true,
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    icon: const Icon(Icons.send),
                    onPressed: _send,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
