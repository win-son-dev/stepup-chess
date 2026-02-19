import 'package:get_it/get_it.dart';
import 'package:stepup_chess/engine/rule_engine_factory.dart';

final getIt = GetIt.instance;

/// Register all app-level services.
///
/// Called once in [main] before [runApp].
void setupServiceLocator() {
  getIt.registerSingleton<RuleEngineFactory>(
    const DefaultRuleEngineFactory(),
  );
}
