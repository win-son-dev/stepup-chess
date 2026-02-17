import 'package:flutter/material.dart';
import 'package:stepup_chess/config/routes.dart';

class StepUpChessApp extends StatelessWidget {
  const StepUpChessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'StepUp Chess',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.green,
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      routerConfig: router,
    );
  }
}
