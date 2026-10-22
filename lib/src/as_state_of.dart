import 'package:an_lifecycle_cancellable/an_lifecycle_cancellable.dart';
import 'package:an_reactive_state/an_reactive_state.dart';
import 'package:an_state/src/tools.dart';
import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';

/// 创建一个可变响应式状态 [RState] 的工厂函数。
///
/// [value] 状态的初始值。
/// [equals] 可选的状态值相等性比较器。
/// [debugLabel] 可选的调试标签。
RStateOf<RState<T>> stateMutableOf<T>(T value,
        {RStateEquality<T>? equals, String? debugLabel}) =>
    (cancellable) =>
        RState(initialValue: value, equals: equals, cancellable: cancellable);

/// 通过计算器闭包创建一个可变响应式状态 [RState] 的工厂函数。
///
/// [computer] 提供初始值的计算逻辑闭包。
/// [equals] 可选的状态值相等性比较器。
/// [debugLabel] 可选的调试标签。
RStateOf<RState<T>> stateMutableOfC<T>(RStateComputer<T> computer,
        {RStateEquality<T>? equals, String? debugLabel}) =>
    (cancellable) =>
        RState(computer: computer, equals: equals, cancellable: cancellable);

/// 创建一个计算状态 [ComputedState] 的工厂函数。
///
/// [computer] 定义计算逻辑，会自动追踪并收集依赖。
/// [equals] 可选的状态值相等性比较器。
/// [debugLabel] 可选的调试标签。
RStateOf<ComputedState<T>> stateOf<T>(RStateComputer<T> computer,
        {RStateEquality<T>? equals, String? debugLabel}) =>
    (cancellable) => ComputedState(
        computer: computer, equals: equals, cancellable: cancellable);

/// 为任意类型 [T] 提供转换为响应式状态工厂的便捷扩展。
extension AnyAsStateExt<T> on T {
  /// 将当前值转换为只读的计算状态工厂 [RStateOf<ComputedState<T>>]。
  RStateOf<ComputedState<T>> get asStateOf => stateOf<T>(() => this);

  /// 将当前值转换为可变状态工厂 [RStateOf<RState<T>>]。
  RStateOf<RState<T>> get asStateMutableOf => stateMutableOf<T>(this);
}

/// 为 [List] 提供转换为响应式列表状态工厂的便捷扩展。
extension ListAsStateExt<T> on List<T> {
  /// 将当前列表转换为只读的不可修改列表计算状态工厂。
  ///
  /// 默认使用 [ListEquality] 作为相等性比较器。
  RStateOf<ComputedState<List<T>>> get asStateOf =>
      stateOf<List<T>>(() => List.unmodifiable(this),
          equals: ListEquality<T>().equals);

  /// 将当前列表转换为可变列表状态工厂。
  ///
  /// 默认使用 [ListEquality] 作为相等性比较器。
  RStateOf<RState<List<T>>> get asStateMutableOf =>
      stateMutableOf<List<T>>(List.of(this), equals: ListEquality<T>().equals);
}

/// 为 [Map] 提供转换为响应式映射状态工厂的便捷扩展。
extension MapAsStateExt<K, V> on Map<K, V> {
  /// 将当前映射转换为只读的不可修改映射计算状态工厂。
  ///
  /// 默认使用 [MapEquality] 作为相等性比较器。
  RStateOf<ComputedState<Map<K, V>>> get asStateOf =>
      stateOf<Map<K, V>>(() => Map.unmodifiable(this),
          equals: MapEquality<K, V>().equals);

  /// 将当前映射转换为可变映射状态工厂。
  ///
  /// 默认使用 [MapEquality] 作为相等性比较器。
  RStateOf<RState<Map<K, V>>> get asStateMutableOf =>
      stateMutableOf<Map<K, V>>(Map.of(this),
          equals: MapEquality<K, V>().equals);
}

/// 为 [Set] 提供转换为响应式集合状态工厂的便捷扩展。
extension SetAsStateExt<E> on Set<E> {
  /// 将当前集合转换为只读的不可修改集合计算状态工厂。
  ///
  /// 默认使用 [SetEquality] 作为相等性比较器。
  RStateOf<ComputedState<Set<E>>> get asStateOf =>
      stateOf<Set<E>>(() => Set.unmodifiable(this),
          equals: SetEquality<E>().equals);

  /// 将当前集合转换为可变集合状态工厂。
  ///
  /// 默认使用 [SetEquality] 作为相等性比较器。
  RStateOf<RState<Set<E>>> get asStateMutableOf =>
      stateMutableOf<Set<E>>(Set.of(this), equals: SetEquality<E>().equals);
}

/// 创建一个初始值为 `null` 的可空计算状态工厂 [RStateOf<ComputedState<T?>>]。
RStateOf<ComputedState<T?>> nullAsStateOf<T>() => stateOf<T?>(() => null);

/// 创建一个初始值为 `null` 的可空可变状态工厂 [RStateOf<RState<T?>>]。
RStateOf<RState<T?>> nullAsStateMutableOf<T>() => stateMutableOf<T?>(null);

/// 为 [bool] 提供转换为响应式状态工厂的便捷扩展。
extension BoolAsStateExt on bool {
  RStateOf<ComputedState<bool>> get asStateOf => stateOf<bool>(() => this);

  RStateOf<RState<bool>> get asStateMutableOf => stateMutableOf<bool>(this);
}

/// 为 [int] 提供转换为响应式状态工厂的便捷扩展。
extension IntAsStateExt on int {
  RStateOf<ComputedState<int>> get asStateOf => stateOf<int>(() => this);

  RStateOf<RState<int>> get asStateMutableOf => stateMutableOf<int>(this);
}

/// 为 [double] 提供转换为响应式状态工厂的便捷扩展。
extension DoubleAsStateExt on double {
  RStateOf<ComputedState<double>> get asStateOf => stateOf<double>(() => this);

  RStateOf<RState<double>> get asStateMutableOf => stateMutableOf<double>(this);
}

/// 为 [num] 提供转换为响应式状态工厂的便捷扩展。
extension NumAsStateExt on num {
  RStateOf<ComputedState<num>> get asStateOf => stateOf<num>(() => this);

  RStateOf<RState<num>> get asStateMutableOf => stateMutableOf<num>(this);
}

/// 为 [String] 提供转换为响应式状态工厂的便捷扩展。
extension StringAsStateExt on String {
  RStateOf<ComputedState<String>> get asStateOf => stateOf<String>(() => this);

  RStateOf<RState<String>> get asStateMutableOf => stateMutableOf<String>(this);
}

/// 为 [DateTime] 提供转换为响应式状态工厂的便捷扩展。
extension DateTimeAsStateExt on DateTime {
  RStateOf<ComputedState<DateTime>> get asStateOf =>
      stateOf<DateTime>(() => this);

  RStateOf<RState<DateTime>> get asStateMutableOf =>
      stateMutableOf<DateTime>(this);
}

/// 为 [Duration] 提供转换为响应式状态工厂的便捷扩展。
extension DurationAsStateExt on Duration {
  RStateOf<ComputedState<Duration>> get asStateOf =>
      stateOf<Duration>(() => this);

  RStateOf<RState<Duration>> get asStateMutableOf =>
      stateMutableOf<Duration>(this);
}

/// 为 [MapEntry] 提供转换为响应式状态工厂的便捷扩展。
extension MapEntryAsStateExt<K, V> on MapEntry<K, V> {
  RStateOf<ComputedState<MapEntry<K, V>>> get asStateOf =>
      stateOf<MapEntry<K, V>>(() => this);

  RStateOf<RState<MapEntry<K, V>>> get asStateMutableOf =>
      stateMutableOf<MapEntry<K, V>>(this);
}

/// 为 [ValueNotifier] 提供转换为响应式状态工厂的便捷扩展。
extension ValueNotifierAsStateExt<T> on ValueNotifier<T> {
  /// 将 [ValueNotifier] 转换为只读的计算状态工厂，并在其值改变时自动刷新状态。
  RStateOf<ComputedState<T>> get asStateOf => (cancellable) {
        final state =
            ComputedState<T>(computer: () => value, cancellable: cancellable);
        addCListener(cancellable, () {
          state.refresh();
        });
        return state;
      };

  /// 将 [ValueNotifier] 转换为可变状态工厂，并在其值改变时自动刷新状态。
  RStateOf<RState<T>> get asStateMutableOf => (cancellable) {
        final state = RState<T>(initialValue: value, cancellable: cancellable);
        addCListener(cancellable, () {
          state.refresh();
        });
        return state;
      };
}
