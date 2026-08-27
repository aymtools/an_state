import 'package:an_reactive_state/an_reactive_state.dart';
import 'package:an_state/src/tools.dart';
import 'package:flutter/widgets.dart';
import 'package:remember/remember.dart';

// ignore: implementation_imports
import 'package:remember/src/tools/element_safe.dart';

extension RememberStateExt on BuildContext {
  /// 可以在使用处和计算器双方都可以进行赋值修改
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
      onCreate: listen
          ? (d, l, c) {
              d.addListener(
                  safeMarkNeedsBuildVoidListener(this, cancellable: c));
            }
          : null,
      key: 'rememberMutableState',
    );
  }

  /// 自动记住和计算新的状态信息 只能使用有其他的 [rememberState] 的内容 不可以与 [rememberListenable] 系列联动
  /// 只可以由计算器对值进行修改，使用处无权修改
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
      onCreate: listen
          ? (d, l, c) {
              d.addListener(
                  safeMarkNeedsBuildVoidListener(this, cancellable: c));
            }
          : null,
      key: 'rememberState',
    );
  }

  T listenRawState<T>(BaseState<T> state) {
    return remember<BaseState<T>>(
      factory: () => state,
      onCreate: (d, l, c) {
        d.addListener(safeMarkNeedsBuildVoidListener(this, cancellable: c));
      },
      key: 'listenRawState',
    ).value;
  }
}
