import 'dart:async';

import 'package:an_async_data/an_async_data.dart';
import 'package:an_lifecycle_cancellable/an_lifecycle_cancellable.dart';
import 'package:an_reactive_state/an_reactive_state.dart';
import 'package:cancellable/cancellable.dart';
import 'package:flutter/foundation.dart';

/// 状态比较函数定义
typedef RStateEquality<T> = bool Function(T, T);

/// 状态计算函数定义
typedef RStateComputer<T> = T Function();

/// 昂贵计算包装器。
/// 只有在首次调用时触发计算逻辑，之后会缓存结果并直接返回。
/// 适用于那些只需要初始化一次的注册逻辑或重度计算。
RStateComputer<T> expensiveComputation<T>(RStateComputer<T> computer) {
  bool computed0 = false;
  T? value;
  return () {
    if (computed0) return value as T;
    value = computer();
    computed0 = true;
    return value as T;
  };
}

/// 创建一个固定值的计算器，不会随上游变化而重新计算。
RStateComputer<T> stateValueOf<T>(T value) => expensiveComputation(() => value);

/// 创建一个固定列表的计算器。
RStateComputer<List<T>> stateListOf<T>(List<T> value) =>
    expensiveComputation(() => value);

/// 创建一个固定映射的计算器。
RStateComputer<Map<K, V>> stateMapOf<K, V>(Map<K, V> value) =>
    expensiveComputation(() => value);

/// 创建一个固定集合的计算器。
RStateComputer<Set<E>> stateSetOf<E>(Set<E> value) =>
    expensiveComputation(() => value);

/// 将 [ValueNotifier] 转换为响应式状态计算器。
/// 当 [ValueNotifier] 的值发生变化时，会自动触发当前响应式上下文的刷新。
RStateComputer<T> stateOfValueNotifier<T>({
  required ValueNotifier<T> valueNotifier,
  String? debugLabel,
}) {
  final init = expensiveComputation(
    () {
      final curr = BaseState.currentState;
      final disposable = curr?.disposable;
      if (disposable != null && disposable.isAvailable) {
        // 将 ValueNotifier 的监听与当前 BaseState 的生命周期绑定
        valueNotifier.addCListener(disposable, () {
          curr?.refresh();
        });
      }
    },
  );
  return () {
    init();
    return valueNotifier.value;
  };
}

/// 将 [ChangeNotifier] 转换为响应式状态计算器。
/// 当 [ChangeNotifier] 发出通知时，会自动触发当前响应式上下文的刷新。
RStateComputer<T> stateOfChangeNotifier<T, CN extends ChangeNotifier>({
  required CN changeNotifier,
  required T Function(CN) computer,
  String? debugLabel,
}) {
  final init = expensiveComputation(
    () {
      final curr = BaseState.currentState;
      final disposable = curr?.disposable;
      if (disposable != null && disposable.isAvailable) {
        // 将 ChangeNotifier 的监听与当前 BaseState 的生命周期绑定
        changeNotifier.addCListener(disposable, () {
          curr?.refresh();
        });
      }
    },
  );
  return () {
    init();
    return computer(changeNotifier);
  };
}

/// 将 [Future] 或 [Stream] 转换为响应式状态计算器。
/// 当异步任务完成或产生新值时，会自动触发当前响应式上下文的刷新。
/// 返回的计算器会先返回 [initialValue]，在异步任务产生新值后返回最新结果。
/// [cancellable] 可以控制是否还可以继续使用
RStateComputer<T> stateOfAsync<T>({
  required T initialValue,
  Future<T>? future,
  Future<T> Function()? fFactory,
  Future<T> Function(Cancellable)? fFactory2,
  Stream<T>? stream,
  Stream<T> Function()? sFactory,
  Stream<T> Function(Cancellable)? sFactory2,
  bool? cancelOnError,
  Function? onError,
  Cancellable? cancellable,
}) {
  T currentValue = initialValue;
  final init = expensiveComputation(() {
    final curr = BaseState.currentState;
    if (curr == null) return;
    final can = curr.disposable.makeCancellable(father: cancellable);
    if (can.isAvailable) {
      void setValue(T value) {
        currentValue = value;
        curr.refresh();
      }

      void listenFuture(Future<T> future) {
        _runFuture(future.bindCancellable(can), setValue, onError);
      }

      if (future != null) {
        listenFuture(future);
      }
      if (fFactory != null) {
        listenFuture(fFactory());
      }
      if (fFactory2 != null) {
        listenFuture(fFactory2(can.makeCancellable()));
      }

      void subStream(Stream<T> stream) {
        stream.bindCancellable(can).listen(
          setValue,
          onError: (Object error, StackTrace stackTrace) {
            _safeRunOnError<T>(onError, error, stackTrace, setValue);
          },
          cancelOnError: cancelOnError,
        );
      }

      if (stream != null) {
        subStream(stream);
      }
      if (sFactory != null) {
        subStream(sFactory());
      }
      if (sFactory2 != null) {
        subStream(sFactory2(can.makeCancellable()));
      }
    }
  });

  return () {
    init();
    return currentValue;
  };
}

/// 将 [Future] 或 [Stream] 转换为响应式状态计算器。
/// 当异步任务完成或产生新值时，会自动触发当前响应式上下文的刷新。
/// 返回的计算器会先返回 [initialValue]，在异步任务产生新值后返回最新结果。
/// [cancellable] 可以控制是否还可以继续使用
RStateComputer<AsyncData<T>> stateOfAsyncData<T>({
  T? initialValue,
  Future<T>? future,
  Future<T> Function()? fFactory,
  Future<T> Function(Cancellable)? fFactory2,
  Stream<T>? stream,
  Stream<T> Function()? sFactory,
  Stream<T> Function(Cancellable)? sFactory2,
  bool? cancelOnError,
  Function? onError,
  Cancellable? cancellable,
}) {
  AsyncData<T> currentValue = initialValue is T
      ? AsyncData<T>.value(initialValue)
      : AsyncData<T>.loading();
  final init = expensiveComputation(() {
    final curr = BaseState.currentState;
    if (curr == null) return;
    final can = curr.disposable.makeCancellable(father: cancellable);
    if (can.isAvailable) {
      void setValue(T value) {
        currentValue = AsyncData<T>.value(value);
        curr.refresh();
      }

      void setError(Object error, StackTrace stackTrace) {
        if (onError == null) {
          currentValue = AsyncData.error(error, stackTrace);
          curr.refresh();
        } else if (onError is dynamic Function(Object, StackTrace)) {
          try {
            dynamic errResult = onError(error, stackTrace);
            if (errResult is T) {
              setValue(errResult);
            }
          } catch (error, stackTrace) {
            currentValue = AsyncData.error(error, stackTrace);
            curr.refresh();
          }
        } else if (onError is dynamic Function(Object)) {
          try {
            dynamic errResult = onError(error);
            if (errResult is T) {
              setValue(errResult);
            }
          } catch (error, stackTrace) {
            currentValue = AsyncData.error(error, stackTrace);
            curr.refresh();
          }
        } else if (onError is dynamic Function()) {
          try {
            dynamic errResult = onError();
            if (errResult is T) {
              setValue(errResult);
            }
          } catch (error, stackTrace) {
            currentValue = AsyncData.error(error, stackTrace);
            curr.refresh();
          }
        } else {
          throw ArgumentError.value(
              onError,
              "onError",
              "Error handler must accept one Object or one Object and a StackTrace"
                  " as arguments");
        }
      }

      void listenFuture(Future<T> future) {
        _runFuture(future.bindCancellable(can), setValue, setError);
      }

      if (future != null) {
        listenFuture(future);
      }
      if (fFactory != null) {
        listenFuture(fFactory());
      }
      if (fFactory2 != null) {
        listenFuture(fFactory2(can.makeCancellable()));
      }

      void subStream(Stream<T> stream) {
        stream.bindCancellable(can).listen(
              setValue,
              onError: setError,
              cancelOnError: cancelOnError,
            );
      }

      if (stream != null) {
        subStream(stream);
      }
      if (sFactory != null) {
        subStream(sFactory());
      }
      if (sFactory2 != null) {
        subStream(sFactory2(can.makeCancellable()));
      }
    }
  });

  return () {
    init();
    return currentValue;
  };
}

void _runFuture<T>(
    Future<T> future, void Function(T) setValue, Function? onError) async {
  try {
    final result = await future;
    setValue(result);
  } catch (error, stackTrace) {
    _safeRunOnError(onError, error, stackTrace, setValue);
  }
}

void _safeRunOnError<T>(Function? onError, Object error, StackTrace stackTrace,
    void Function(T) setValue) {
  if (onError != null) {
    dynamic errResult;
    bool hasValue = false;
    if (onError is dynamic Function(Object, StackTrace)) {
      errResult = onError(error, stackTrace);
      hasValue = true;
    } else if (onError is dynamic Function(Object)) {
      errResult = onError(error);
      hasValue = true;
    } else if (onError is dynamic Function()) {
      errResult = onError();
      hasValue = true;
    } else {
      throw ArgumentError.value(
          onError,
          "onError",
          "Error handler must accept one Object or one Object and a StackTrace"
              " as arguments");
    }
    if (hasValue && errResult is T) {
      setValue(errResult);
    }
  }
}
