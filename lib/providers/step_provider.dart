import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stepup_chess/services/step_tracker_service.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Must be overridden in ProviderScope');
});

final stepTrackerServiceProvider = Provider<StepTrackerService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final service = StepTrackerService(prefs);
  service.startListening();
  ref.onDispose(() => service.dispose());
  return service;
});

final stepBagProvider = StreamProvider<int>((ref) {
  final service = ref.watch(stepTrackerServiceProvider);
  // Emit current value immediately, then stream updates
  return Stream.value(service.stepBag).asyncExpand(
    (initial) => Stream.value(initial).followedBy(service.stepBagStream),
  );
});

extension _StreamExtension<T> on Stream<T> {
  Stream<T> followedBy(Stream<T> other) {
    final controller = StreamController<T>();
    listen(
      controller.add,
      onError: controller.addError,
      onDone: () {
        other.listen(
          controller.add,
          onError: controller.addError,
          onDone: controller.close,
        );
      },
    );
    return controller.stream;
  }
}
