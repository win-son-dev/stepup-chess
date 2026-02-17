import 'package:go_router/go_router.dart';
import 'package:stepup_chess/screens/home/home_screen.dart';
import 'package:stepup_chess/screens/game/create_game_screen.dart';
import 'package:stepup_chess/screens/game/game_screen.dart';

final router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/create',
      builder: (context, state) => const CreateGameScreen(),
    ),
    GoRoute(
      path: '/game',
      builder: (context, state) => const GameScreen(),
    ),
  ],
);
