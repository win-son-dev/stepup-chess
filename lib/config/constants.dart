import 'package:stepup_chess/models/step_cost_preset.dart';

const String stepBagKey = 'step_bag_balance';
const String stepBaselineKey = 'step_baseline';
const String lastKnownStepsKey = 'last_known_steps';

const String gameFenKey = 'game_fen';
const String gamePresetNameKey = 'game_preset_name';
const String gameStatusKey = 'game_status';
const String gameMoveHistoryKey = 'game_move_history';

final List<StepCostPreset> presets = [
  StepCostPreset(
    name: 'Quick',
    pawn: 2,
    knight: 5,
    bishop: 5,
    rook: 7,
    queen: 10,
    king: 3,
  ),
  StepCostPreset(
    name: 'Normal',
    pawn: 50,
    knight: 80,
    bishop: 80,
    rook: 100,
    queen: 150,
    king: 30,
  ),
  StepCostPreset(
    name: 'Marathon',
    pawn: 200,
    knight: 350,
    bishop: 350,
    rook: 500,
    queen: 750,
    king: 100,
  ),
];
