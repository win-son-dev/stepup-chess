import 'dart:async';
import 'package:pedometer_2/pedometer_2.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stepup_chess/config/constants.dart';

class StepTrackerService {
  final SharedPreferences _prefs;
  final Pedometer _pedometer = Pedometer();
  StreamSubscription<int>? _subscription;

  int _baseline = 0;
  int _stepBagBalance = 0;
  int _lastKnownSteps = 0;

  final _stepBagController = StreamController<int>.broadcast();
  Stream<int> get stepBagStream => _stepBagController.stream;
  int get stepBag => _stepBagBalance;

  StepTrackerService(this._prefs) {
    _loadPersistedState();
  }

  void _loadPersistedState() {
    _stepBagBalance = _prefs.getInt(stepBagKey) ?? 0;
    _baseline = _prefs.getInt(stepBaselineKey) ?? 0;
    _lastKnownSteps = _prefs.getInt(lastKnownStepsKey) ?? 0;
  }

  void startListening() {
    _subscription = _pedometer.stepCountStream().listen(
      _onStepCount,
      onError: _onStepCountError,
    );
  }

  void _onStepCount(int newCumulative) {
    // Detect reboot: if cumulative is less than last known, pedometer reset
    if (newCumulative < _lastKnownSteps) {
      _baseline = newCumulative;
      _prefs.setInt(stepBaselineKey, _baseline);
    }

    // First reading after app start
    if (_baseline == 0 && _lastKnownSteps == 0) {
      _baseline = newCumulative;
      _prefs.setInt(stepBaselineKey, _baseline);
    }

    _lastKnownSteps = newCumulative;
    _prefs.setInt(lastKnownStepsKey, _lastKnownSteps);

    // New steps earned since baseline
    final newSteps = newCumulative - _baseline;
    if (newSteps > 0) {
      _stepBagBalance += newSteps;
      _baseline = newCumulative;
      _persistBalance();
    }

    _stepBagController.add(_stepBagBalance);
  }

  void _onStepCountError(dynamic error) {
    // Pedometer not available — step bag stays at current balance
  }

  bool canAfford(int cost) => _stepBagBalance >= cost;

  bool spendSteps(int cost) {
    if (_stepBagBalance < cost) return false;
    _stepBagBalance -= cost;
    _persistBalance();
    _stepBagController.add(_stepBagBalance);
    return true;
  }

  /// For testing: add steps manually
  void addSteps(int steps) {
    _stepBagBalance += steps;
    _persistBalance();
    _stepBagController.add(_stepBagBalance);
  }

  void _persistBalance() {
    _prefs.setInt(stepBagKey, _stepBagBalance);
    _prefs.setInt(stepBaselineKey, _baseline);
  }

  void dispose() {
    _subscription?.cancel();
    _stepBagController.close();
  }
}
