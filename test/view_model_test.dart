import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:an_state/an_state.dart';
import 'package:an_viewmodel/an_viewmodel.dart';
import 'package:anlifecycle/anlifecycle.dart';

class CounterViewModel extends ViewModel {
  late final count = stateMutableOf(stateValueOf(0));
  late final doubleCount = stateOf(() => count.value * 2);

  void increment() => count.value++;
}

void main() {
  group('ViewModel Extensions', () {
    testWidgets(
        'ViewModel reactive state should update and be accessible via context.viewModels()',
        (WidgetTester tester) async {
      late CounterViewModel vm;
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

      expect(find.text('Count: 0'), findsOneWidget);
      expect(find.text('Double: 0'), findsOneWidget);

      vm.increment();
      await tester.pump();

      expect(find.text('Count: 1'), findsOneWidget);
      expect(find.text('Double: 2'), findsOneWidget);
    });
  });
}
