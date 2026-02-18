import 'package:flutter/material.dart';
import 'package:stepup_chess/config/routes.dart';

/// Warm wood + green palette to match the board.
const _woodDark = Color(0xFF3E2723); // dark walnut
const _woodMid = Color(0xFF5D4037); // medium wood
const _woodLight = Color(0xFF8D6E63); // lighter grain
const _boardGreen = Color(0xFF558B2F); // board green accent
const _cream = Color(0xFFFFF8E1); // parchment/cream background

class StepUpChessApp extends StatelessWidget {
  const StepUpChessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'StepUp Chess',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.light(
          primary: _boardGreen,
          onPrimary: Colors.white,
          primaryContainer: const Color(0xFFC5E1A5),
          secondary: _woodMid,
          onSecondary: Colors.white,
          surface: _cream,
          onSurface: _woodDark,
          outline: _woodLight,
        ),
        scaffoldBackgroundColor: _cream,
        appBarTheme: const AppBarTheme(
          backgroundColor: _woodDark,
          foregroundColor: Color(0xFFFFF8E1),
          elevation: 2,
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFFFFF3E0),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: _boardGreen,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: _woodMid,
            side: const BorderSide(color: _woodLight),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        segmentedButtonTheme: SegmentedButtonThemeData(
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return _boardGreen;
              }
              return const Color(0xFFFFF3E0);
            }),
            foregroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return Colors.white;
              }
              return _woodDark;
            }),
          ),
        ),
        snackBarTheme: const SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: _cream,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: const Color(0xFFFFF3E0),
          side: BorderSide(color: _woodLight.withValues(alpha: 0.5)),
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            color: _woodDark,
            fontWeight: FontWeight.bold,
          ),
          bodyLarge: TextStyle(color: _woodMid),
        ),
        iconTheme: const IconThemeData(color: _boardGreen),
      ),
      routerConfig: router,
    );
  }
}
