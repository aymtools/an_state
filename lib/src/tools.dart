import 'package:an_lifecycle_cancellable/an_lifecycle_cancellable.dart';
import 'package:an_reactive_state/an_reactive_state.dart';
import 'package:flutter/foundation.dart';

typedef RStateEquality<T> = bool Function(T, T);

typedef RStateComputer<T> = T Function();

/// 只会触发首次计算，首次计算完成后，后续不会再次触发计算。永久性的不会恢复。
RStateComputer<T> expensiveComputation<T>(RStateComputer<T> computer) {
  bool computed0 = false;
  T? value;
  return () {
    if (computed0) return value as T;
    value = computer();
    computed0 = true;
    return value as T;
  };
}

/// 固定返回值，切上游任何变化不会重新计算
RStateComputer<T> stateValueOf<T>(T value) => expensiveComputation(() => value);

RStateComputer<List<T>> stateListOf<T>(List<T> value) =>
    expensiveComputation(() => value);

RStateComputer<Map<K, V>> stateMapOf<K, V>(Map<K, V> value) =>
    expensiveComputation(() => value);

RStateComputer<Set<E>> stateSetOf<E>(Set<E> value) =>
    expensiveComputation(() => value);

RStateComputer<T> stateOfValueNotifier<T>({
  required ValueNotifier<T> valueNotifier,
  String? debugLabel,
}) {
  final init = expensiveComputation(
    () {
      final curr = BaseState.currentState;
      final disposable = curr?.disposable;
      if (disposable != null && disposable.isAvailable) {
        valueNotifier.addCListener(disposable, () {
          // print('stateOfValueNotifier need refresh');
          curr?.refresh();
        });
      }
    },
  );
  return () {
    init();
    return valueNotifier.value;
  };
}

RStateComputer<T> stateOfChangeNotifier<T, CN extends ChangeNotifier>({
  required CN changeNotifier,
  required T Function(CN) computer,
  String? debugLabel,
}) {
  final init = expensiveComputation(
    () {
      final curr = BaseState.currentState;
      final disposable = curr?.disposable;
      if (disposable != null && disposable.isAvailable) {
        changeNotifier.addCListener(disposable, () {
          // print('stateOfChangeNotifier need refresh');
          curr?.refresh();
        });
      }
    },
  );
  return () {
    init();
    return computer(changeNotifier);
  };
}
