import 'package:stepup_chess/engine/rule_engine.dart';
import 'package:stepup_chess/engine/standard_chess_rules.dart';

/// Supported chess rule variants.
enum RuleVariant { standard, khmer }

/// Factory interface for creating [RuleEngine] instances.
///
/// A single registered factory produces different engines at runtime based on
/// [RuleVariant]. Adding a new variant only requires adding a case here and
/// implementing [RuleEngine] — nothing else changes.
abstract class RuleEngineFactory {
  RuleEngine create(RuleVariant variant);
}

/// Concrete factory that dispatches on [RuleVariant] to produce the right engine.
class DefaultRuleEngineFactory implements RuleEngineFactory {
  const DefaultRuleEngineFactory();

  @override
  RuleEngine create(RuleVariant variant) {
    switch (variant) {
      case RuleVariant.standard:
        return StandardChessRules();
      case RuleVariant.khmer:
        throw UnimplementedError('KhmerChessRules is not yet implemented');
    }
  }
}
