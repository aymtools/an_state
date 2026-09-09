import 'package:an_async_data/an_async_data.dart';
import 'package:an_reactive_state/an_reactive_state.dart';

extension AsyncDataStateExt<T> on RState<AsyncData<T>> {
  bool get isLoading => value.isLoading;

  bool get isError => value.isError;

  bool get isData => value is AsyncDataValue<T>;

  bool get hasData => value.hasData;

  T get data => value.data;

  T? get dataOrNull => value.dataOrNull;

  Object get error => value.error;

  StackTrace? get stackTrace => value.stackTrace;

  void toLoading() => value = AsyncData<T>.loading();

  void toData(T data) => value = AsyncData<T>.data(data);

  void toError(Object error, [StackTrace? stackTrace]) =>
      value = AsyncData<T>.error(error, stackTrace);

  void toDataLoading() => value = hasData
      ? AsyncData<T>.dataLoading(_getInnerData())
      : AsyncData<T>.loading();

  void toDataLoadingRaw(T data) => value = AsyncData<T>.dataLoading(data);

  void toDataError(Object error, [StackTrace? stackTrace]) => value = hasData
      ? AsyncData<T>.dataError(_getInnerData(), error, stackTrace)
      : AsyncData<T>.error(error, stackTrace);

  void toDataErrorRaw(T data, Object error, [StackTrace? stackTrace]) =>
      value = AsyncData<T>.dataError(data, error, stackTrace);

  T _getInnerData() {
    if (hasData) {
      final that = value;
      if (that is AsyncDataValue<T>) {
        return that.data;
      } else if (that is AsyncDataLoading<T>) {
        return that.data as T;
      } else if (that is AsyncDataError<T>) {
        return that.data as T;
      }
    }
    throw StateError('AsyncData<$T> not has data');
  }
}
