import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:an_state/an_state.dart';
import 'package:anlifecycle/anlifecycle.dart';

void main() {
  group('BuildContext Extensions (remember)', () {
    testWidgets('rememberMutableState should persist and trigger rebuild', (WidgetTester tester) async {
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

    testWidgets('rememberState should update when dependency changes', (WidgetTester tester) async {
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
                  final computer = stateOfValueNotifier(valueNotifier: notifier);
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
  });
}
