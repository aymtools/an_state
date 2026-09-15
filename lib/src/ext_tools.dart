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
}

extension AsStateOfValueNotifierExt<T> on ValueNotifier<T> {
  RStateComputer<T> get asStateOf => stateOfValueNotifier<T>(this);
}
