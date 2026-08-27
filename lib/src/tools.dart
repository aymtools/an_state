import 'package:an_lifecycle_cancellable/an_lifecycle_cancellable.dart';
import 'package:an_reactive_state/an_reactive_state.dart';
import 'package:flutter/foundation.dart';

/// 状态比较函数定义
typedef RStateEquality<T> = bool Function(T, T);

/// 状态计算函数定义
typedef RStateComputer<T> = T Function();

/// 昂贵计算包装器。
/// 只有在首次调用时触发计算逻辑，之后会缓存结果并直接返回。
/// 适用于那些只需要初始化一次的注册逻辑或重度计算。
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

/// 创建一个固定值的计算器，不会随上游变化而重新计算。
RStateComputer<T> stateValueOf<T>(T value) => expensiveComputation(() => value);

/// 创建一个固定列表的计算器。
RStateComputer<List<T>> stateListOf<T>(List<T> value) =>
    expensiveComputation(() => value);

/// 创建一个固定映射的计算器。
RStateComputer<Map<K, V>> stateMapOf<K, V>(Map<K, V> value) =>
    expensiveComputation(() => value);

/// 创建一个固定集合的计算器。
RStateComputer<Set<E>> stateSetOf<E>(Set<E> value) =>
    expensiveComputation(() => value);

/// 将 [ValueNotifier] 转换为响应式状态计算器。
/// 当 [ValueNotifier] 的值发生变化时，会自动触发当前响应式上下文的刷新。
RStateComputer<T> stateOfValueNotifier<T>({
  required ValueNotifier<T> valueNotifier,
  String? debugLabel,
}) {
  final init = expensiveComputation(
    () {
      final curr = BaseState.currentState;
      final disposable = curr?.disposable;
      if (disposable != null && disposable.isAvailable) {
        // 将 ValueNotifier 的监听与当前 BaseState 的生命周期绑定
        valueNotifier.addCListener(disposable, () {
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

/// 将 [ChangeNotifier] 转换为响应式状态计算器。
/// 当 [ChangeNotifier] 发出通知时，会自动触发当前响应式上下文的刷新。
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
        // 将 ChangeNotifier 的监听与当前 BaseState 的生命周期绑定
        changeNotifier.addCListener(disposable, () {
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
