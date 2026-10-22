import 'package:an_reactive_state/an_reactive_state.dart';
import 'package:an_state/src/tools.dart';
import 'package:anlifecycle/anlifecycle.dart';
import 'package:cancellable/cancellable.dart';
import 'package:flutter/widgets.dart';
import 'package:remember/remember.dart';

// ignore: implementation_imports
import 'package:remember/src/tools/element_safe.dart';

/// 为 [BuildContext] 提供的状态绑定与监听扩展。
///
/// 允许在 Widget 树中记忆（Remember）状态以及监听响应式状态变化。
extension RememberStateExt on BuildContext {
  /// 在 Widget 树中记住一个响应式状态 [S]。
  ///
  /// 状态的生命周期与当前 Widget 树中的节点绑定，在组件销毁时自动注销和释放。
  ///
  /// [stateOf] 状态定义构建器（如 `stateMutableOf`、`stateOf`、`stateRefreshableOf` 等）。
  /// [debugLabel] 可选的调试标签。
  /// [listen] 是否在状态发生变化时自动触发当前 Widget 重新构建，默认为 `true`。
  S rememberState<S extends BaseState>(
    RStateOf<S> stateOf, {
    String? debugLabel,
    bool listen = true,
  }) {
    return remember<S>(
      factory3: (l, c) => stateOf(c),
      onCreate: listen ? onCreateListen : null,
      key: 'rememberState',
    );
  }

  /// 监听并消费一个响应式状态。
  ///
  /// [listenReactiveState] 的别名方法。当 [state] 发生变化时，会自动触发当前 Widget 重新构建并返回最新值。
  T listenRawState<T>(BaseState<T> state) => listenReactiveState(state);

  /// 监听并消费一个响应式状态。
  ///
  /// 在 Widget 构建期间建立依赖，当 [state] 的值发生变化时，会自动触发当前 Widget 重新构建，并返回其最新值。
  T listenReactiveState<T>(BaseState<T> state) {
    return remember<BaseState<T>>(
      factory: () => state,
      onCreate: onCreateListen,
      key: 'listenReactiveState',
    ).value;
  }

  /// 在当前 Widget 中同时监听并消费多个响应式状态。
  ///
  /// 在 [computer] 闭包内访问的所有响应式状态都会被自动收集依赖。
  /// 只要其中任意一个状态发生变化，就会自动触发当前 Widget 重新构建。
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

/// 为 [BuildContext] 提供的状态监听扩展辅助类。
extension RememberStateOnCreateListenExt on BuildContext {
  /// 获取用于将状态变更与 Widget 刷新动作关联的回调函数。
  void Function(BaseState<dynamic> state, Lifecycle lifecycle,
      Cancellable cancellable) get onCreateListen => (BaseState<dynamic> state,
          Lifecycle lifecycle, Cancellable cancellable) =>
      state.addListener(
          safeMarkNeedsBuildVoidListener(this, cancellable: cancellable));
}
