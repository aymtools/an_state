import 'package:an_async_data/an_async_data.dart';
import 'package:an_reactive_state/an_reactive_state.dart';

/// 针对 [RState<AsyncData<T>>] 类型的响应式异步数据状态扩展。
///
/// 提供了对异步数据状态 [AsyncData] 的便捷查询 getters（如判断加载状态、提取数据或错误）
/// 以及快速进行状态变更与流转的方法（如 [toLoading]、[toData]、[toDataLoading] 等）。
extension AsyncDataStateExt<T> on RState<AsyncData<T>> {
  /// 当前状态是否处于加载中。
  ///
  /// 包括首次加载 [AsyncDataLoading] 以及带有旧数据的重新加载 [AsyncDataDataLoading]。
  bool get isLoading => value.isLoading;

  /// 当前状态是否处于错误状态。
  ///
  /// 包括纯错误状态 [AsyncDataError] 以及带有旧数据的错误状态 [AsyncDataDataError]。
  bool get isError => value.isError;

  /// 当前状态是否为成功数据状态 [AsyncDataValue]。
  bool get isData => value is AsyncDataValue<T>;

  /// 当前状态中是否包含有效数据。
  ///
  /// 当处于 [AsyncDataValue]、[AsyncDataDataLoading] 或 [AsyncDataDataError] 状态时返回 `true`。
  bool get hasData => value.hasData;

  /// 获取当前状态中的数据。
  ///
  /// 注意：如果当前状态不包含有效数据（[hasData] 为 `false`），调用此属性会抛出异常。
  /// 建议先使用 [hasData] 检查，或直接使用 [dataOrNull]。
  T get data => value.data;

  /// 安全获取当前状态中的数据，若不包含数据则返回 `null`。
  T? get dataOrNull => value.dataOrNull;

  /// 获取当前状态中的错误对象。
  ///
  /// 注意：如果当前状态未发生错误（[isError] 为 `false`），调用此属性会抛出异常。
  Object get error => value.error;

  /// 获取当前状态中的错误堆栈信息（若有）。
  StackTrace? get stackTrace => value.stackTrace;

  /// 将当前状态重置为纯加载中状态 [AsyncData.loading]。
  ///
  /// 这会清空之前可能存在的任何缓存数据。
  void toLoading() => value = AsyncData<T>.loading();

  /// 将当前状态更新为成功数据状态 [AsyncData.data]。
  ///
  /// [data] 成功获取的数据。
  void toData(T data) => value = AsyncData<T>.data(data);

  /// 将当前状态更新为纯错误状态 [AsyncData.error]。
  ///
  /// [error] 捕获到的异常或错误对象。
  /// [stackTrace] 可选的错误堆栈信息。
  void toError(Object error, [StackTrace? stackTrace]) =>
      value = AsyncData<T>.error(error, stackTrace);

  /// 将当前状态切换为加载中状态。
  ///
  /// 如果当前已存在有效数据（[hasData] 为 `true`），则转为带有旧数据的加载状态 [AsyncData.dataLoading]，
  /// 允许 UI 在重新加载时继续展示旧数据（实现静默刷新/加载指示效果）；
  /// 如果不包含数据，则切换为纯加载状态 [AsyncData.loading]。
  void toDataLoading() => value = hasData
      ? AsyncData<T>.dataLoading(_getInnerData())
      : AsyncData<T>.loading();

  /// 强制将当前状态切换为带指定旧数据 [data] 的加载中状态 [AsyncData.dataLoading]。
  ///
  /// [data] 重新加载期间需要保留展示的数据。
  void toDataLoadingRaw(T data) => value = AsyncData<T>.dataLoading(data);

  /// 将当前状态切换为错误状态。
  ///
  /// 如果当前已存在有效数据（[hasData] 为 `true`），则转为带有旧数据的错误状态 [AsyncData.dataError]，
  /// 允许 UI 在保留展示旧数据的同时向用户提示错误（如 Toast/SnackBar）；
  /// 如果不包含数据，则切换为纯错误状态 [AsyncData.error]。
  ///
  /// [error] 捕获到的异常或错误对象。
  /// [stackTrace] 可选的错误堆栈信息。
  void toDataError(Object error, [StackTrace? stackTrace]) => value = hasData
      ? AsyncData<T>.dataError(_getInnerData(), error, stackTrace)
      : AsyncData<T>.error(error, stackTrace);

  /// 强制将当前状态切换为带指定旧数据 [data] 的错误状态 [AsyncData.dataError]。
  ///
  /// [data] 发生错误时仍需要保留展示的数据。
  /// [error] 捕获到的异常或错误对象。
  /// [stackTrace] 可选的错误堆栈信息。
  void toDataErrorRaw(T data, Object error, [StackTrace? stackTrace]) =>
      value = AsyncData<T>.dataError(data, error, stackTrace);

  /// 获取内部有效数据，若无数据则抛出 [StateError]。
  T _getInnerData() {
    if (hasData) {
      return value.data;
    }
    throw StateError('AsyncData<$T> not has data');
  }
}
