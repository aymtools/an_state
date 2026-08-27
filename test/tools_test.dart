import 'package:cancellable/cancellable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:an_state/an_state.dart';

void main() {


  group('Tools', () {
    test('expensiveComputation should only run once', () {
      int callCount = 0;
      final computer = expensiveComputation(() {
        callCount++;
        return "result";
      });

      expect(callCount, 0);
      expect(computer(), "result");
      expect(callCount, 1);
      expect(computer(), "result");
      expect(callCount, 1);
    });

    test('stateOfValueNotifier should observe changes', () {
      final notifier = ValueNotifier(0);
      int computeCount = 0;
      final computer = stateOfValueNotifier(valueNotifier: notifier);
      final reactive = ComputedState(
        computer: () {
          computeCount++;
          return computer();
        },
        cancellable:  Cancellable(),
      );

      expect(reactive.value, 0);
      expect(computeCount, 1);

      notifier.value = 1;
      expect(computeCount, 1);
      expect(reactive.value, 1);
      expect(computeCount, 2);
    });

    test('stateOfChangeNotifier should observe changes', () {
      final notifier = ValueNotifier(0); // ValueNotifier is a ChangeNotifier
      int computeCount = 0;
      final computer = stateOfChangeNotifier(
        changeNotifier: notifier,
        computer: (cn) => cn.value,
      );
      final reactive = ComputedState(
        computer: () {
          computeCount++;
          return computer();
        },
        cancellable: Cancellable(),
      );

      expect(reactive.value, 0);
      expect(computeCount, 1);

      notifier.value = 1;
      expect(reactive.value, 1);
      expect(computeCount, 2);
    });
  });
}
