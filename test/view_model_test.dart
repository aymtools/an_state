import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:an_state/an_state.dart';
import 'package:an_viewmodel/an_viewmodel.dart';
import 'package:anlifecycle/anlifecycle.dart';

/// 测试专用的计数器 ViewModel，用于验证 ViewModel 的状态绑定与生命周期管理。
class CounterViewModel extends ViewModel {
  /// 可变状态：计数器
  late final count = state(stateMutableOf(0));
  
  /// 计算状态：计数器的两倍
  late final doubleCount = state(stateOf(() => count.value * 2));

  /// 计数器自增操作
  void increment() => count.value++;
}

/// ViewModel 扩展与生命周期绑定的单元测试套件。
void main() {
  group('ViewModel Extensions', () {
    /// 测试点：验证 ViewModel 中的响应式状态能够在值修改时自动更新，
    /// 并且能够通过 context.viewModels() 正确获取并被 Widget 消费。
    testWidgets(
        'ViewModel reactive state should update and be accessible via context.viewModels()',
        (WidgetTester tester) async {
      late CounterViewModel vm;

      // 渲染组件树并获取 ViewModel 实例
      await tester.pumpWidget(
        MaterialApp(
          home: LifecycleScopeOwner(
            scope: 'test',
            child: Builder(
              builder: (context) {
                vm = context.viewModels<CounterViewModel>(
                    factory: CounterViewModel.new);
                return Column(
                  children: [
                    Text('Count: ${context.listenRawState(vm.count)}'),
                    Text('Double: ${context.listenRawState(vm.doubleCount)}'),
                  ],
                );
              },
            ),
          ),
        ),
      );

      // 验证初始状态值为 0
      expect(find.text('Count: 0'), findsOneWidget);
      expect(find.text('Double: 0'), findsOneWidget);

      // 执行自增操作
      vm.increment();
      await tester.pump();

      // 验证状态自增后，UI 联动更新为 1 和 2
      expect(find.text('Count: 1'), findsOneWidget);
      expect(find.text('Double: 2'), findsOneWidget);
    });
  });
}
