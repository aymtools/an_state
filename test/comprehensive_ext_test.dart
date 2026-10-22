import 'package:an_state/an_state.dart';
import 'package:an_viewmodel/an_viewmodel.dart';
import 'package:anlifecycle/anlifecycle.dart';
import 'package:cancellable/cancellable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// 用于测试 ViewModel 多状态管理与生命周期副作用的测试 ViewModel。
class MultiStateViewModel extends ViewModel {
  /// 定义第一个可变状态
  late final count = state(stateMutableOf(10));
  
  /// 定义第二个可变状态
  late final name = state(stateMutableOf('Dart'));

  /// 定义计算状态，依赖 count 和 name
  late final summary = state(stateOf(() => '${name.value}: ${count.value}'));

  /// 记录 useEffect 被触发的次数
  int effectRunCount = 0;
  int lastCountValue = 0;

  bool _initialized = false;

  /// 初始化测试副作用（确保只初始化一次）
  void initTestEffect() {
    if (_initialized) return;
    _initialized = true;
    // 注册 useEffect 监听 count 的变化
    useEffect(() {
      effectRunCount++;
      lastCountValue = count.value;
    });
  }

  /// 自增 count 值
  void increment() {
    count.value++;
  }

  /// 更新 name 值
  void updateName(String newName) {
    name.value = newName;
  }
}

/// 综合单元测试文件：验证 an_state 库中各个扩展工具、ValueNotifier 转换、ViewModel 多状态管理及高级异步状态变更。
/// 所有测试用例名称均为英文，并配有详尽的中文注释。
void main() {
  group('Comprehensive Extensions & Tools Tests', () {
    
    /// 测试点 1：验证基础类型、集合类型的 asStateComputation 与 asNullableStateComputation 扩展转换
    test('Object and Collection asStateComputation extension getters', () {
      // 整型数值测试
      final intComp = 100.asStateComputation;
      expect(intComp(), 100);

      final nullableIntComp = 200.asNullableStateComputation;
      expect(nullableIntComp(), 200);

      // 字符串测试
      final strComp = 'Hello Flutter'.asStateComputation;
      expect(strComp(), 'Hello Flutter');

      // 列表测试
      final list = [1, 2, 3];
      final listComp = list.asStateComputation;
      expect(listComp(), [1, 2, 3]);

      // 映射测试
      final map = {'key': 'value'};
      final mapComp = map.asStateComputation;
      expect(mapComp(), {'key': 'value'});

      // 集合测试
      final set = {10, 20};
      final setComp = set.asStateComputation;
      expect(setComp(), {10, 20});

      // 空值初始化器测试
      final nullComp = nullAsStateComputation<String>();
      expect(nullComp(), isNull);
    });

    /// 测试点 2：验证 ValueNotifier 的 asStateComputation 扩展及其响应式监听机制
    test('ValueNotifier asStateComputation and reactive updates', () async {
      final notifier = ValueNotifier<int>(5);

      // 将 ValueNotifier 转换为状态计算器
      final computer = notifier.asStateComputation;
      expect(computer(), 5);

      // 创建依赖该计算器的 ComputedState
      final cancellable = Cancellable();
      final computed = ComputedState(
        computer: computer,
        cancellable: cancellable,
      );

      expect(computed.value, 5);

      // 更新 ValueNotifier 的值
      notifier.value = 15;
      expect(computer(), 15);

      cancellable.cancel();
    });

    /// 测试点 3：验证 ViewModel 中定义多种状态（可变状态、计算状态）及 useEffect 副作用
    testWidgets('ViewModel multi-state management and useEffect execution',
        (WidgetTester tester) async {
      late MultiStateViewModel vm;

      // 渲染组件并获取 ViewModel 实例
      await tester.pumpWidget(
        MaterialApp(
          home: LifecycleScopeOwner(
            scope: 'test',
            child: Builder(
              builder: (context) {
                vm = context.viewModels<MultiStateViewModel>(
                    factory: MultiStateViewModel.new);
                vm.initTestEffect();
                return Column(
                  children: [
                    Text('Summary: ${context.listenRawState(vm.summary)}'),
                  ],
                );
              },
            ),
          ),
        ),
      );

      // 验证初始状态
      expect(find.text('Summary: Dart: 10'), findsOneWidget);
      expect(vm.effectRunCount, 1); // useEffect 初始化时会执行一次
      expect(vm.lastCountValue, 10);

      // 修改 count，验证计算状态和 useEffect 联动
      vm.increment();
      await tester.pump();
      expect(find.text('Summary: Dart: 11'), findsOneWidget);
      expect(vm.effectRunCount, 2);
      expect(vm.lastCountValue, 11);

      // 修改 name，验证 summary 随之更新但 useEffect 的 count 监听未增加触发次数
      vm.updateName('Flutter');
      await tester.pump();
      expect(find.text('Summary: Flutter: 11'), findsOneWidget);
      expect(vm.effectRunCount, 2); // count 未变，useEffect 次数保持不变
    });

    /// 测试点 4：验证 AsyncDataStateExt 高级状态突变方法（toDataError, toDataErrorRaw, toDataLoadingRaw 等）
    test('AsyncDataStateExt advanced mutations (toDataError, toDataLoadingRaw)', () {
      final state = RState<AsyncData<String>>(
        initialValue: AsyncData<String>.loading(),
        cancellable: Cancellable(),
      );

      // 初始状态为加载中
      expect(state.isLoading, isTrue);
      expect(state.hasData, isFalse);

      // 测试 toDataLoadingRaw 强制带旧数据的加载状态
      state.toDataLoadingRaw('cached data');
      expect(state.isLoading, isTrue);
      expect(state.hasData, isTrue);
      expect(state.data, 'cached data');

      // 测试 toDataError 在有旧数据时的行为（应转为 dataError 状态，保留旧数据）
      final st1 = StackTrace.current;
      state.toDataError('network error', st1);
      expect(state.isError, isTrue);
      expect(state.hasData, isTrue);
      expect(state.data, 'cached data');
      expect(state.error, 'network error');
      expect(state.stackTrace, st1);

      // 测试 toDataErrorRaw 强制带指定旧数据的错误状态
      final st2 = StackTrace.current;
      state.toDataErrorRaw('fallback data', 'critical error', st2);
      expect(state.isError, isTrue);
      expect(state.hasData, isTrue);
      expect(state.data, 'fallback data');
      expect(state.error, 'critical error');
      expect(state.stackTrace, st2);

      // 重置为纯加载状态，验证无数据时 toDataError 会退化为纯 error 状态
      state.toLoading();
      expect(state.hasData, isFalse);

      state.toDataError('pure error');
      expect(state.isError, isTrue);
      expect(state.hasData, isFalse);
      expect(state.error, 'pure error');
    });
  });
}
