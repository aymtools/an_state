import 'package:an_reactive_state/an_reactive_state.dart';
import 'package:an_state/src/tools.dart';
import 'package:an_viewmodel/an_viewmodel.dart';
import 'package:cancellable/cancellable.dart';

/// 为 [ViewModel] 提供的响应式状态管理扩展。
extension ViewmodelStateExt on ViewModel {
  /// 在 [ViewModel] 中声明并绑定一个响应式状态 [S]。
  ///
  /// 该方法将通过 [stateOf] 工厂创建状态，并将其生命周期绑定到 ViewModel 的 [makeLiveCancellable]。
  /// 当 ViewModel 销毁（Cleared）时，该状态会自动被释放并取消关联任务。
  ///
  /// [stateOf] 状态定义构建器（如 `stateMutableOf`、`stateOf`、`stateRefreshableOf` 等）。
  /// [debugLabel] 可选的调试标签。
  S state<S extends BaseState>(
    RStateOf<S> stateOf, {
    String? debugLabel,
  }) {
    return stateOf(makeLiveCancellable(weakRef: false));
  }

  /// 在 [ViewModel] 中启动一个与生命周期绑定的响应式副作用 [effect]。
  ///
  /// [action] 闭包中访问的任意响应式状态发生变化时，都会重新触发 [action] 执行。
  /// 副作用的生命周期与当前 ViewModel 绑定，当 ViewModel 销毁时自动注销。
  ///
  /// [cancellable] 可选的额外取消句柄。
  void useEffect(void Function() action, {Cancellable? cancellable}) =>
      effect(action, cancellable: makeLiveCancellable(other: cancellable));
}
