import 'package:an_reactive_state/an_reactive_state.dart';
import 'package:an_state/src/tools.dart';
import 'package:an_viewmodel/an_viewmodel.dart';

extension ViewmodelStateExt on ViewModel {
  /// 在 ViewModel 中创建一个可变状态 [RState]。
  /// 该状态的生命周期将与 ViewModel 绑定，在 ViewModel 销毁时自动释放。
  /// [computer] 提供初始值计算逻辑。
  RState<T> stateMutableOf<T>(
    RStateComputer<T> computer, {
    RStateEquality<T>? equals,
    String? debugLabel,
  }) =>
      RState(
          initialValue: computer(),
          cancellable: makeLiveCancellable(),
          equals: equals);

  /// 在 ViewModel 中创建一个计算状态 [ComputedState]。
  /// 该状态会自动收集依赖，并与 ViewModel 生命周期绑定。
  /// [computer] 定义计算逻辑。
  ComputedState<T> stateOf<T>(
    RStateComputer<T> computer, {
    RStateEquality<T>? equals,
    String? debugLabel,
  }) =>
      ComputedState(
          computer: computer,
          cancellable: makeLiveCancellable(),
          equals: equals);
}
