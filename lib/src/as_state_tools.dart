import 'package:an_lifecycle_cancellable/an_lifecycle_cancellable.dart';
import 'package:an_reactive_state/an_reactive_state.dart';
import 'package:an_state/src/tools.dart';
import 'package:flutter/foundation.dart';

/// 为常规非空对象（Object）提供的状态计算器转换扩展。
extension AsStateComputationObjectExt<T extends Object> on T {
  /// 将当前对象转换为非空的 [RStateComputer] 计算闭包。
  ///
  /// 内部通过 [expensiveComputation] 包装，确保计算和求值只执行一次。
  RStateComputer<T> get asStateComputation => expensiveComputation(() => this);

  /// 将当前对象转换为可空的 [RStateComputer<T?>] 计算闭包。
  RStateComputer<T?> get asNullableStateComputation =>
      expensiveComputation<T?>(() => this);
}

/// 为 [ValueNotifier] 提供的状态计算器转换扩展。
extension AsStateComputationValueNotifierExt<T> on ValueNotifier<T> {
  /// 将 [ValueNotifier] 转换为 [RStateComputer] 计算闭包。
  ///
  /// 当 [ValueNotifier] 的值发生变化时，会自动触发当前响应式上下文的刷新。
  RStateComputer<T> get asStateComputation => valueNotifierComputation<T>(this);

  /// 将 [ValueNotifier] 转换为可空的 [RStateComputer<T?>] 计算闭包。
  ///
  /// 同时会将 [ValueNotifier] 的监听器与当前 `BaseState` 的生命周期绑定。
  RStateComputer<T?> get asNullableStateComputation {
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

/// 创建一个固定返回 `null` 的可空 [RStateComputer<T?>] 初始值计算闭包。
RStateComputer<T?> nullAsStateComputation<T>() =>
    expensiveComputation<T?>(() => null);
