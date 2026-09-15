import 'package:an_state/an_state.dart';
import 'package:anlifecycle/anlifecycle.dart';
import 'package:cancellable/cancellable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BuildContext Extensions (remember)', () {
    testWidgets('rememberMutableState should persist and trigger rebuild',
        (WidgetTester tester) async {
      int buildCount = 0;
      late RState<int> state;

      await tester.pumpWidget(
        MaterialApp(
          home: LifecycleScopeOwner(
            scope: 'test',
            child: Scaffold(
              body: Builder(
                builder: (context) {
                  buildCount++;
                  state = context.rememberMutableState(stateValueOf(0));
                  return Text('Value: ${state.value}');
                },
              ),
            ),
          ),
        ),
      );

      expect(find.text('Value: 0'), findsOneWidget);
      expect(buildCount, 1);

      // Trigger change
      state.value = 10;
      await tester.pump();

      expect(find.text('Value: 10'), findsOneWidget);
      expect(buildCount, 2);
    });

    testWidgets('rememberState should update when dependency changes',
        (WidgetTester tester) async {
      final notifier = ValueNotifier(0);
      int buildCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: LifecycleScopeOwner(
            scope: 'test',
            child: Scaffold(
              body: Builder(
                builder: (context) {
                  buildCount++;
                  final computer = stateOfValueNotifier(notifier);
                  final reactive = context.rememberState(() => computer());
                  return Text('Value: ${reactive.value}');
                },
              ),
            ),
          ),
        ),
      );

      expect(find.text('Value: 0'), findsOneWidget);
      expect(buildCount, 1);

      // Change notifier
      notifier.value = 5;
      await tester.pump();

      expect(find.text('Value: 5'), findsOneWidget);
      expect(buildCount, 2);
    });

    testWidgets(
        'listenReactiveState should return state value and trigger rebuild on change',
        (WidgetTester tester) async {
      final cancellable = Cancellable();
      final state = RState<int>(
        initialValue: 0,
        cancellable: cancellable,
      );
      int buildCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: LifecycleScopeOwner(
            scope: 'test',
            child: Scaffold(
              body: Builder(
                builder: (context) {
                  buildCount++;
                  final val = context.listenReactiveState(state);
                  return Text('Value: $val');
                },
              ),
            ),
          ),
        ),
      );

      expect(find.text('Value: 0'), findsOneWidget);
      expect(buildCount, 1);

      // Trigger state change
      state.value = 42;
      await tester.pump();

      expect(find.text('Value: 42'), findsOneWidget);
      expect(buildCount, 2);
    });

    testWidgets(
        'listenRawState should delegate to listenReactiveState and trigger rebuild',
        (WidgetTester tester) async {
      final cancellable = Cancellable();
      final state = RState<int>(
        initialValue: 100,
        cancellable: cancellable,
      );
      int buildCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: LifecycleScopeOwner(
            scope: 'test',
            child: Scaffold(
              body: Builder(
                builder: (context) {
                  buildCount++;
                  final val = context.listenRawState(state);
                  return Text('Value: $val');
                },
              ),
            ),
          ),
        ),
      );

      expect(find.text('Value: 100'), findsOneWidget);
      expect(buildCount, 1);

      state.value = 200;
      await tester.pump();

      expect(find.text('Value: 200'), findsOneWidget);
      expect(buildCount, 2);
    });

    testWidgets(
        'listenReactiveStates should observe multiple states and trigger rebuild',
        (WidgetTester tester) async {
      final cancellable = Cancellable();
      final state1 = RState<int>(
        initialValue: 1,
        cancellable: cancellable,
      );
      final state2 = RState<String>(
        initialValue: 'A',
        cancellable: cancellable,
      );
      int buildCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: LifecycleScopeOwner(
            scope: 'test',
            child: Scaffold(
              body: Builder(
                builder: (context) {
                  buildCount++;
                  context.listenReactiveStates(() {
                    // Read reactive state values
                    state1.value;
                    state2.value;
                  });
                  return Text('State: ${state1.value}-${state2.value}');
                },
              ),
            ),
          ),
        ),
      );

      expect(find.text('State: 1-A'), findsOneWidget);
      expect(buildCount, 1);

      // Change first state
      state1.value = 2;
      await tester.pump();

      expect(find.text('State: 2-A'), findsOneWidget);
      expect(buildCount, 2);

      // Change second state
      state2.value = 'B';
      await tester.pump();

      expect(find.text('State: 2-B'), findsOneWidget);
      expect(buildCount, 3);
    });
  });
}
