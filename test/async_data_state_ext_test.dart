import 'package:an_async_data/an_async_data.dart';
import 'package:an_state/an_state.dart';
import 'package:cancellable/cancellable.dart';
import 'package:flutter_test/flutter_test.dart';

/// 针对 [AsyncDataStateExt] 扩展的单元测试套件。
/// 验证异步数据状态（加载中、数据成功、错误）的 getters 查询与突变方法的行为。
void main() {
  group('AsyncDataStateExt', () {
    
    /// 测试点 1：验证 getters 在 loading、data 和 error 状态下的正确性及安全访问边界
    test('Getters work correctly for loading, data, and error states', () {
      final state = RState<AsyncData<int>>(
        initialValue: AsyncData<int>.loading(),
        cancellable: Cancellable(),
      );

      // 1. 验证加载中状态 (Loading State) 下的各项属性
      expect(state.isLoading, isTrue);
      expect(state.isError, isFalse);
      expect(state.isData, isFalse);
      expect(state.hasData, isFalse);
      expect(state.dataOrNull, isNull);
      expect(() => state.data, throwsStateError); // 无数据时直接访问 .data 应抛出状态异常
      expect(() => state.error, throwsStateError); // 无错误时直接访问 .error 应抛出状态异常
      expect(state.stackTrace, isNull);

      // 2. 切换至成功数据状态 (Data State) 并验证属性
      state.toData(42);
      expect(state.isLoading, isFalse);
      expect(state.isError, isFalse);
      expect(state.isData, isTrue);
      expect(state.hasData, isTrue);
      expect(state.data, 42);
      expect(state.dataOrNull, 42);
      expect(() => state.error, throwsStateError); // 有数据无错误时访问 .error 应抛出异常

      // 3. 切换至错误状态 (Error State) 并验证属性与堆栈
      final st = StackTrace.current;
      state.toError('an error', st);
      expect(state.isLoading, isFalse);
      expect(state.isError, isTrue);
      expect(state.isData, isFalse);
      expect(state.hasData, isFalse);
      expect(state.dataOrNull, isNull);
      expect(state.error, 'an error');
      expect(state.stackTrace, st);
    });

    /// 测试点 2：验证 toLoading、toData 和 toError 状态变更方法能够正确更新状态并触发响应式依赖通知
    test('toLoading, toData, and toError update state and trigger reactivity',
        () {
      final state = RState<AsyncData<String>>(
        initialValue: AsyncData<String>.loading(),
        cancellable: Cancellable(),
      );
      int computeCount = 0;

      // 创建一个 ComputedState 追踪 state 的变化
      final computed = ComputedState(
        computer: () {
          computeCount++;
          return state.value;
        },
        cancellable: Cancellable(),
      );

      expect(computed.value, AsyncData<String>.loading());
      expect(computeCount, 1);

      // 更新为成功数据状态，验证计算状态重新触发
      state.toData('hello');
      expect(computed.value, AsyncData<String>.data('hello'));
      expect(computeCount, 2);

      // 更新为错误状态，验证计算状态重新触发
      final st = StackTrace.current;
      state.toError('err', st);
      expect(computed.value, AsyncData<String>.error('err', st));
      expect(computeCount, 3);

      // 重新置为加载状态，验证计算状态重新触发
      state.toLoading();
      expect(computed.value, AsyncData<String>.loading());
      expect(computeCount, 4);
    });

    /// 测试点 3：验证无数据 vs 有旧数据时 toDataLoading 方法的行为差异（静默刷新逻辑）
    test('toDataLoading when hasData is true vs false', () {
      final state = RState<AsyncData<int>>(
        initialValue: AsyncData<int>.loading(),
        cancellable: Cancellable(),
      );

      // 当没有旧数据时，toDataLoading 应转为纯加载状态 AsyncData.loading
      state.toDataLoading();
      expect(state.value, AsyncData<int>.loading());
      expect(state.hasData, isFalse);

      // 写入有效数据
      state.toData(100);
      expect(state.hasData, isTrue);
      expect(state.data, 100);

      // 当已有数据时，toDataLoading 应转为带旧数据的加载状态 dataLoading(100)
      state.toDataLoading();
      expect(state.value, AsyncData<int>.dataLoading(100));
      expect(state.hasData, isTrue);
      expect(state.isLoading, isTrue);

      // 重复调用 toDataLoading 应持续保持旧数据和加载状态
      state.toDataLoading();
      expect(state.value, AsyncData<int>.dataLoading(100));
      expect(state.hasData, isTrue);
    });

    /// 测试点 4：验证 toDataLoadingRaw 能够强制设置指定的原始旧数据并进入加载状态
    test('toDataLoadingRaw sets dataLoading with specified raw data', () {
      final state = RState<AsyncData<int>>(
        initialValue: AsyncData<int>.loading(),
        cancellable: Cancellable(),
      );

      state.toDataLoadingRaw(50);
      expect(state.value, AsyncData<int>.dataLoading(50));
      expect(state.hasData, isTrue);
      expect(state.isLoading, isTrue);
    });

    /// 测试点 5：验证无数据 vs 有旧数据时 toDataError 方法的行为差异
    test('toDataError when hasData is true vs false', () {
      final state = RState<AsyncData<int>>(
        initialValue: AsyncData<int>.loading(),
        cancellable: Cancellable(),
      );
      final st = StackTrace.current;

      // 当无数据时，toDataError 应转为纯错误状态 AsyncData.error
      state.toDataError('err1', st);
      expect(state.value, AsyncData<int>.error('err1', st));
      expect(state.hasData, isFalse);
      expect(state.isError, isTrue);

      // 写入有效数据
      state.toData(200);
      expect(state.hasData, isTrue);

      // 当有数据时，toDataError 应转为带旧数据的错误状态 dataError(200, 'err2', st)
      state.toDataError('err2', st);
      expect(state.value, AsyncData<int>.dataError(200, 'err2', st));
      expect(state.hasData, isTrue);
      expect(state.isError, isTrue);

      // 随后可以通过 toDataLoading 再次转回带旧数据的加载状态
      state.toDataLoading();
      expect(state.value, AsyncData<int>.dataLoading(200));
      expect(state.hasData, isTrue);
    });

    /// 测试点 6：验证 toDataErrorRaw 能够强制设置指定旧数据与错误信息
    test('toDataErrorRaw sets dataError with specified raw data', () {
      final state = RState<AsyncData<int>>(
        initialValue: AsyncData<int>.loading(),
        cancellable: Cancellable(),
      );
      final st = StackTrace.current;

      state.toDataErrorRaw(300, 'raw error', st);
      expect(state.value, AsyncData<int>.dataError(300, 'raw error', st));
      expect(state.hasData, isTrue);
      expect(state.isError, isTrue);
    });
  });
}
