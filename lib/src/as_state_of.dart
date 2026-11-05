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
RStateOf<RState<T>> stateOfValue<T>(T value,
        {RStateEquality<T>? equals, String? debugLabel}) =>
    (cancellable) =>
        RState(initialValue: value, equals: equals, cancellable: cancellable);

/// 通过计算器闭包创建一个可变响应式状态 [RState] 的工厂函数。
///
/// [computer] 提供初始值的计算逻辑闭包。
/// [equals] 可选的状态值相等性比较器。
/// [debugLabel] 可选的调试标签。
RStateOf<RState<T>> stateOfMutableComputation<T>(RStateComputer<T> computer,
        {RStateEquality<T>? equals, String? debugLabel}) =>
    (cancellable) =>
        RState(computer: computer, equals: equals, cancellable: cancellable);

/// 创建一个计算状态 [ComputedState] 的工厂函数。
///
/// [computer] 定义计算逻辑，会自动追踪并收集依赖。
/// [equals] 可选的状态值相等性比较器。
/// [debugLabel] 可选的调试标签。
RStateOf<ComputedState<T>> stateOfComputation<T>(RStateComputer<T> computer,
        {RStateEquality<T>? equals, String? debugLabel}) =>
    (cancellable) => ComputedState(
        computer: computer, equals: equals, cancellable: cancellable);

/// 为任意类型 [T] 提供转换为响应式状态工厂的便捷扩展。
extension AnyAsStateExt<T> on T {
  /// 将当前值转换为可变状态工厂 [RStateOf<RState<T>>]。
  RStateOf<RState<T>> get asStateOf => stateOfValue<T>(this);

  /// 将当前值转换为可变可空状态工厂 [RStateOf<RState<T?>>]。
  RStateOf<RState<T?>> get asStateOfNullable => stateOfValue<T?>(this);
}

/// 为 [List] 提供转换为响应式列表状态工厂的便捷扩展。
extension ListAsStateExt<T> on List<T> {
  /// 将当前列表拷贝转换为可变列表状态工厂 [RStateOf<RState<List<T>>>]。
  ///
  /// 默认使用 [ListEquality] 作为相等性比较器。
  RStateOf<RState<List<T>>> get asStateOf =>
      stateOfValue<List<T>>(List.of(this), equals: ListEquality<T>().equals);

  /// 将当前列表拷贝转换为可变可空列表状态工厂 [RStateOf<RState<List<T>?>>]。
  ///
  /// 默认使用 [ListEquality] 作为相等性比较器。
  RStateOf<RState<List<T>?>> get asStateOfNullable =>
      stateOfValue<List<T>?>(List.of(this), equals: ListEquality<T>().equals);
}

/// 创建一个响应式列表状态工厂 [RStateOf<RState<List<T>>>]。
///
/// [source] 可选的初始列表数据源。
RStateOf<RState<List<T>>> stateOfList<T>({List<T>? source}) =>
    stateOfValue<List<T>>(source == null ? <T>[] : List.of(source),
        equals: ListEquality<T>().equals);

/// 为 [Map] 提供转换为响应式映射状态工厂的便捷扩展。
extension MapAsStateExt<K, V> on Map<K, V> {
  /// 将当前映射拷贝转换为可变映射状态工厂 [RStateOf<RState<Map<K, V>>>]。
  ///
  /// 默认使用 [MapEquality] 作为相等性比较器。
  RStateOf<RState<Map<K, V>>> get asStateOf =>
      stateOfValue<Map<K, V>>(Map.of(this), equals: MapEquality<K, V>().equals);

  /// 将当前映射拷贝转换为可变可空映射状态工厂 [RStateOf<RState<Map<K, V>?>>]。
  ///
  /// 默认使用 [MapEquality] 作为相等性比较器。
  RStateOf<RState<Map<K, V>?>> get asStateOfNullable =>
      stateOfValue<Map<K, V>?>(Map.of(this),
          equals: MapEquality<K, V>().equals);
}

/// 创建一个响应式映射状态工厂 [RStateOf<RState<Map<K, V>>>]。
///
/// [source] 可选的初始映射数据源。
RStateOf<RState<Map<K, V>>> stateOfMap<K, V>({Map<K, V>? source}) =>
    stateOfValue<Map<K, V>>(source == null ? <K, V>{} : Map<K, V>.of(source),
        equals: MapEquality<K, V>().equals);

/// 为 [Set] 提供转换为响应式集合状态工厂的便捷扩展。
extension SetAsStateExt<E> on Set<E> {
  /// 将当前集合拷贝转换为可变可空集合状态工厂 [RStateOf<RState<Set<E>?>>]。
  ///
  /// 默认使用 [SetEquality] 作为相等性比较器。
  RStateOf<RState<Set<E>?>> get asStateOfNullable =>
      stateOfValue<Set<E>?>(Set.of(this), equals: SetEquality<E>().equals);

  /// 将当前集合拷贝转换为可变集合状态工厂 [RStateOf<RState<Set<E>>>]。
  ///
  /// 默认使用 [SetEquality] 作为相等性比较器。
  RStateOf<RState<Set<E>>> get asStateOf =>
      stateOfValue<Set<E>>(Set.of(this), equals: SetEquality<E>().equals);
}

/// 创建一个响应式集合状态工厂 [RStateOf<RState<Set<E>>>]。
///
/// [source] 可选的初始集合数据源。
RStateOf<RState<Set<E>>> stateOfSet<E>({Set<E>? source}) =>
    stateOfValue<Set<E>>(source == null ? <E>{} : Set.of(source),
        equals: SetEquality<E>().equals);

/// 创建一个初始值为 `null` 的可空状态工厂 [RStateOf<RState<T?>>]。
RStateOf<RState<T?>> nullAsStateOf<T>() => stateOfValue<T?>(null);

/// 创建一个初始值为 `null` 的可空状态工厂 [RStateOf<RState<T?>>]。
RStateOf<RState<T?>> stateOfNull<T>() => stateOfValue<T?>(null);

/// 为 [bool] 类型提供转换为响应式状态工厂的便捷扩展。
extension BoolAsStateExt on bool {
  /// 将当前布尔值转换为可变状态工厂 [RStateOf<RState<bool>>]。
  RStateOf<RState<bool>> get asStateOf => stateOfValue<bool>(this);

  /// 将当前布尔值转换为可变可空状态工厂 [RStateOf<RState<bool?>>]。
  RStateOf<RState<bool?>> get asStateOfNullable => stateOfValue<bool?>(this);
}

/// 为 [int] 类型提供转换为响应式状态工厂的便捷扩展。
extension IntAsStateExt on int {
  /// 将当前整数值转换为可变状态工厂 [RStateOf<RState<int>>]。
  RStateOf<RState<int>> get asStateOf => stateOfValue<int>(this);

  /// 将当前整数值转换为可变可空状态工厂 [RStateOf<RState<int?>>]。
  RStateOf<RState<int?>> get asStateOfNullable => stateOfValue<int?>(this);
}

/// 为 [double] 类型提供转换为响应式状态工厂的便捷扩展。
extension DoubleAsStateExt on double {
  /// 将当前双精度浮点数值转换为可变状态工厂 [RStateOf<RState<double?>>]。
  RStateOf<RState<double?>> get asStateOf => stateOfValue<double?>(this);

  /// 将当前双精度浮点数值转换为可变可空状态工厂 [RStateOf<RState<double?>>]。
  RStateOf<RState<double?>> get asStateOfNullable =>
      stateOfValue<double?>(this);
}

/// 为 [num] 类型提供转换为响应式状态工厂的便捷扩展。
extension NumAsStateExt on num {
  /// 将当前数值转换为可变状态工厂 [RStateOf<RState<num>>]。
  RStateOf<RState<num>> get asStateOf => stateOfValue<num>(this);

  /// 将当前数值转换为可变可空状态工厂 [RStateOf<RState<num?>>]。
  RStateOf<RState<num?>> get asStateOfNullable => stateOfValue<num?>(this);
}

/// 为 [String] 类型提供转换为响应式状态工厂的便捷扩展。
extension StringAsStateExt on String {
  /// 将当前字符串转换为可变状态工厂 [RStateOf<RState<String>>]。
  RStateOf<RState<String>> get asStateOf => stateOfValue<String>(this);

  /// 将当前字符串转换为可变可空状态工厂 [RStateOf<RState<String?>>]。
  RStateOf<RState<String?>> get asStateOfNullable =>
      stateOfValue<String?>(this);
}

/// 为 [DateTime] 类型提供转换为响应式状态工厂的便捷扩展。
extension DateTimeAsStateExt on DateTime {
  /// 将当前日期时间对象转换为可变状态工厂 [RStateOf<RState<DateTime>>]。
  RStateOf<RState<DateTime>> get asStateOf => stateOfValue<DateTime>(this);

  /// 将当前日期时间对象转换为可变可空状态工厂 [RStateOf<RState<DateTime?>>]。
  RStateOf<RState<DateTime?>> get asStateOfNullable =>
      stateOfValue<DateTime?>(this);
}

/// 为 [Duration] 类型提供转换为响应式状态工厂的便捷扩展。
extension DurationAsStateExt on Duration {
  /// 将当前时间间隔对象转换为可变状态工厂 [RStateOf<RState<Duration>>]。
  RStateOf<RState<Duration>> get asStateOf => stateOfValue<Duration>(this);

  /// 将当前时间间隔对象转换为可变可空状态工厂 [RStateOf<RState<Duration?>>]。
  RStateOf<RState<Duration?>> get asStateOfNullable =>
      stateOfValue<Duration?>(this);
}

/// 为 [MapEntry] 类型提供转换为响应式状态工厂的便捷扩展。
extension MapEntryAsStateExt<K, V> on MapEntry<K, V> {
  /// 将当前键值对条目转换为可变状态工厂 [RStateOf<RState<MapEntry<K, V>>>]。
  RStateOf<RState<MapEntry<K, V>>> get asStateOf =>
      stateOfValue<MapEntry<K, V>>(this);

  /// 将当前键值对条目转换为可变可空状态工厂 [RStateOf<RState<MapEntry<K, V>?>>]。
  RStateOf<RState<MapEntry<K, V>?>> get asStateOfNullable =>
      stateOfValue<MapEntry<K, V>?>(this);
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
  RStateOf<RState<T>> get asStateOfMutable => (cancellable) {
        final state = RState<T>(initialValue: value, cancellable: cancellable);
        addCListener(cancellable, () {
          state.refresh();
        });
        // effect(() {
        //   final v = state.value;
        //   this.value = v;
        // }, cancellable: cancellable);
        return state;
      };
}
