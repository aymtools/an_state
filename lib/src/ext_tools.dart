import 'package:an_lifecycle_cancellable/an_lifecycle_cancellable.dart';
import 'package:an_reactive_state/an_reactive_state.dart';
import 'package:an_state/src/tools.dart';
import 'package:flutter/foundation.dart';

extension AsStateOfObjectExt<T extends Object> on T {
  RStateComputer<T> get asStateOf => stateValueOf(this);

  RStateComputer<T?> get asNullableStateOf => stateValueOf<T?>(this);
}

extension AsStateOfListExt<T> on List<T> {
  RStateComputer<List<T>> get asStateOf => stateListOf(this);

  RStateComputer<List<T>?> get asNullableStateOf =>
      expensiveComputation<List<T>?>(() => this);
}

extension AsStateOfSetExt<T> on Set<T> {
  RStateComputer<Set<T>> get asStateOf => stateSetOf(this);

  RStateComputer<Set<T>?> get asNullableStateOf =>
      expensiveComputation<Set<T>?>(() => this);
}

extension AsStateOfMapExt<K, V> on Map<K, V> {
  RStateComputer<Map<K, V>> get asStateOf => stateMapOf(this);

  RStateComputer<Map<K, V>?> get asNullableStateOf =>
      expensiveComputation<Map<K, V>?>(() => this);
}

extension AsStateOfValueNotifierExt<T> on ValueNotifier<T> {
  RStateComputer<T> get asStateOf => stateOfValueNotifier<T>(this);

  RStateComputer<T?> get asNullableStateOf {
    {
      final init = expensiveComputation(
        () {
          final curr = BaseState.currentState;
          final disposable = curr?.disposable;
          if (disposable != null && disposable.isAvailable) {
            // 将 ValueNotifier 的监听与当前 BaseState 的生命周期绑定
            addCListener(disposable, () {
              curr?.refresh();
            });
          }
        },
      );
      return () {
        init();
        return value;
      };
    }
  }
}

RStateComputer<T?> nullAsStateOf<T>() => stateValueOf<T?>(null);
