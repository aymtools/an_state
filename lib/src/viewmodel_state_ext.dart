import 'package:an_reactive_state/an_reactive_state.dart';
import 'package:an_state/src/tools.dart';
import 'package:an_viewmodel/an_viewmodel.dart';

extension ViewmodelStateExt on ViewModel {
  /// 可以在使用处和计算器双方都可以进行赋值修改
  RState<T> stateMutableOf<T>(
    RStateComputer<T> computer, {
    RStateEquality<T>? equals,
    String? debugLabel,
  }) =>
      RState(
          initialValue: computer(),
          cancellable: makeLiveCancellable(),
          equals: equals);

  /// 自动记住和计算新的状态信息 只能使用有其他的 [stateOf] 的内容 不可以与 [Notifier] 系列联动
  /// 只可以由计算器对值进行修改，使用处无权修改
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
