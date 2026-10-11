import 'package:an_reactive_state/an_reactive_state.dart';
import 'package:an_state/src/tools.dart';
import 'package:anlifecycle/anlifecycle.dart';
import 'package:cancellable/cancellable.dart';
import 'package:flutter/widgets.dart';
import 'package:remember/remember.dart';

// ignore: implementation_imports
import 'package:remember/src/tools/element_safe.dart';

extension RememberStateExt on BuildContext {
  /// 在 Widget 树中记住一个可变状态 [RState]。
  /// 类似于 Compose 的 `remember { mutableStateOf(...) }`。
  /// [computer] 提供初始值。
  /// [listen] 是否在状态变化时自动刷新当前 Widget。
  RState<T> rememberMutableState<T>(
    RStateComputer<T> computer, {
    RStateEquality<T>? equals,
    String? debugLabel,
    bool listen = true,
  }) {
    return remember<RState<T>>(
      factory3: (l, c) {
        return RState(initialValue: computer(), cancellable: c, equals: equals);
      },
      onCreate: listen ? onCreateListen : null,
      key: 'rememberMutableState',
    );
  }

  /// 在 Widget 树中记住一个计算状态 [ComputedState]。
  /// 类似于 Compose 的 `remember(inputs) { derivedStateOf(...) }`。
  /// [computer] 定义计算逻辑，会自动收集依赖。
  /// [listen] 是否在计算结果变化时自动刷新当前 Widget。
  ComputedState<T> rememberState<T>(
    RStateComputer<T> computer, {
    RStateEquality<T>? equals,
    String? debugLabel,
    bool listen = true,
  }) {
    return remember<ComputedState<T>>(
      factory3: (l, c) {
        return ComputedState(
            computer: computer, cancellable: c, equals: equals);
      },
      onCreate: listen ? onCreateListen : null,
      key: 'rememberState',
    );
  }

  /// 监听并消费一个响应式状态。
  /// 当 [state] 发生变化时，会自动触发当前 Widget 的重新构建，并返回最新值。
  T listenRawState<T>(BaseState<T> state) => listenReactiveState(state);

  /// 监听并消费一个响应式状态。
  /// 当 [state] 发生变化时，会自动触发当前 Widget 的重新构建，并返回最新值。
  T listenReactiveState<T>(BaseState<T> state) {
    return remember<BaseState<T>>(
      factory: () => state,
      onCreate: onCreateListen,
      key: 'listenReactiveState',
    ).value;
  }

  /// 监听并消费多个响应式状态。
  void listenReactiveStates(RStateComputer<void> computer) {
    remember<Object>(
      factory3: (_, cancellable) {
        final rElement = WeakReference(this as Element);
        effect(() {
          elementSafeMarkNeedsBuild(rElement, cancellable: cancellable);
          computer();
        }, cancellable: cancellable);
        return const Object();
      },
    );
  }
}

extension RememberStateOnCreateListenExt on BuildContext {
  void Function(BaseState<dynamic> state, Lifecycle lifecycle,
      Cancellable cancellable) get onCreateListen => (BaseState<dynamic> state,
          Lifecycle lifecycle, Cancellable cancellable) =>
      state.addListener(
          safeMarkNeedsBuildVoidListener(this, cancellable: cancellable));
}
