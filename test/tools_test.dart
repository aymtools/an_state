import 'dart:async';

import 'package:an_state/an_state.dart';
import 'package:cancellable/cancellable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

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
        cancellable: Cancellable(),
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

    test('stateOfAsync (Future) should observe changes', () async {
      final completer = Completer<int>();
      int computeCount = 0;
      final computer = stateOfAsync(
        future: completer.future,
        initialValue: 0,
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

      completer.complete(42);
      await Future.delayed(Duration.zero);

      expect(reactive.value, 42);
      expect(computeCount, 2);
    });

    test('stateOfAsync (Future Error) should handle error', () async {
      final completer = Completer<int>();
      Object? capturedError;
      final computer = stateOfAsync<int>(
        future: completer.future,
        initialValue: 0,
        onError: (e, s) {
          capturedError = e;
          return -1; // Fallback value
        },
      );
      final reactive = ComputedState(
        computer: () => computer(),
        cancellable: Cancellable(),
      );

      expect(reactive.value, 0);

      completer.completeError('test error');
      await Future.delayed(Duration.zero);

      expect(capturedError, 'test error');
      // Verify fallback value is applied
      expect(reactive.value, -1);
    });

    test('stateOfAsync (Stream) should observe changes', () async {
      final controller = StreamController<int>();
      int computeCount = 0;
      final computer = stateOfAsync(
        steam: controller.stream,
        initialValue: 0,
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

      controller.add(42);
      await Future.delayed(Duration.zero);

      expect(reactive.value, 42);
      expect(computeCount, 2);

      controller.add(100);
      await Future.delayed(Duration.zero);
      expect(reactive.value, 100);
      expect(computeCount, 3);

      controller.close();
    });

    test('stateOfAsync (Stream Error) should handle error', () async {
      final controller = StreamController<int>();
      Object? capturedError;
      final computer = stateOfAsync<int>(
        steam: controller.stream,
        initialValue: 0,
        onError: (e, s) {
          capturedError = e;
          return -2;
        },
      );
      final reactive = ComputedState(
        computer: () => computer(),
        cancellable: Cancellable(),
      );

      expect(reactive.value, 0);

      controller.addError('stream error');
      await Future.delayed(Duration.zero);

      expect(capturedError, 'stream error');
      expect(reactive.value, -2);
      controller.close();
    });

    test('stateOfAsync (Stream cancelOnError: true)', () async {
      final controller = StreamController<int>();
      int errorCount = 0;
      final computer = stateOfAsync<int>(
        steam: controller.stream,
        initialValue: 0,
        cancelOnError: true,
        onError: (e) {
          errorCount++;
          return -1;
        },
      );
      final reactive = ComputedState(
        computer: () => computer(),
        cancellable: Cancellable(),
      );
      expect(reactive.value, 0); // Start subscription

      controller.add(1);
      await Future.delayed(Duration.zero);
      expect(reactive.value, 1);

      controller.addError('error');
      await Future.delayed(Duration.zero);
      expect(reactive.value, -1);
      expect(errorCount, 1);

      controller.add(2);
      await Future.delayed(Duration.zero);
      // Should NOT update because it was cancelled on error
      expect(reactive.value, -1);

      controller.close();
    });

    test('stateOfAsync onError signatures', () async {
      final c1 = Completer<int>();
      final comp1 =
          stateOfAsync<int>(future: c1.future, initialValue: 0, onError: () => 1);
      final r1 = ComputedState(
        computer: () => comp1(),
        cancellable: Cancellable(),
      );
      expect(r1.value, 0); // Start subscription

      final c2 = Completer<int>();
      final comp2 =
          stateOfAsync<int>(future: c2.future, initialValue: 0, onError: (e) => 2);
      final r2 = ComputedState(
        computer: () => comp2(),
        cancellable: Cancellable(),
      );
      expect(r2.value, 0); // Start subscription

      final c3 = Completer<int>();
      final comp3 = stateOfAsync<int>(
          future: c3.future, initialValue: 0, onError: (e, s) => 3);
      final r3 = ComputedState(
        computer: () => comp3(),
        cancellable: Cancellable(),
      );
      expect(r3.value, 0); // Start subscription

      c1.completeError('e');
      c2.completeError('e');
      c3.completeError('e');

      await Future.delayed(Duration.zero);

      expect(r1.value, 1);
      expect(r2.value, 2);
      expect(r3.value, 3);
    });

    test('stateOfAsync with already completed future', () async {
      final completer = Completer<int>()..complete(42);
      final computer = stateOfAsync<int>(
        future: completer.future,
        initialValue: 0,
      );
      final reactive = ComputedState(
        computer: () => computer(),
        cancellable: Cancellable(),
      );

      expect(reactive.value, 0); // Still 0 initially because then() is async

      await Future.delayed(Duration.zero);
      expect(reactive.value, 42);
    });

    test('stateOfAsync outside of reactive context should not subscribe', () async {
      final controller = StreamController<int>();
      final computer = stateOfAsync<int>(
        steam: controller.stream,
        initialValue: 0,
      );

      // Call it outside of ComputedState
      expect(computer(), 0);

      controller.add(1);
      await Future.delayed(Duration.zero);

      // Should still be 0 because no subscription was made (no BaseState.currentState)
      expect(computer(), 0);

      controller.close();
    });

    test('stateOfAsync should return current value without triggering new subscriptions', () async {
      final controller = StreamController<int>();
      final computer = stateOfAsync<int>(
        steam: controller.stream,
        initialValue: 0,
      );

      final reactive = ComputedState(
        computer: () => computer(),
        cancellable: Cancellable(),
      );
      expect(reactive.value, 0);
      
      expect(computer(), 0);
      expect(computer(), 0);
      
      controller.add(1);
      await Future.delayed(Duration.zero);
      
      expect(computer(), 1);
      expect(computer(), 1);
      
      controller.close();
    });

    test('stateOfAsync should cancel subscription when context is disposed', () async {
      final controller = StreamController<int>();
      int computeCount = 0;
      final cancellable = Cancellable();
      
      final computer = stateOfAsync(
        steam: controller.stream,
        initialValue: 0,
      );

      final reactive = ComputedState(
        computer: () {
          computeCount++;
          return computer();
        },
        cancellable: cancellable,
      );

      expect(reactive.value, 0);
      expect(computeCount, 1);
      
      controller.add(1);
      await Future.delayed(Duration.zero);
      expect(reactive.value, 1);
      expect(computeCount, 2);

      cancellable.cancel();
      
      controller.add(2);
      await Future.delayed(Duration.zero);
      
      // Should still be 1 because subscription should be cancelled
      expect(reactive.value, 1);
      expect(computeCount, 2);
      
      controller.close();
    });

    test('stateOfAsync with explicit cancellable', () async {
      final controller = StreamController<int>();
      final manualCancellable = Cancellable();

      final computer = stateOfAsync(
        steam: controller.stream,
        initialValue: 0,
        cancellable: manualCancellable,
      );

      final reactive = ComputedState(
        computer: () => computer(),
        cancellable: Cancellable(),
      );

      expect(reactive.value, 0);

      controller.add(1);
      await Future.delayed(Duration.zero);
      expect(reactive.value, 1);

      manualCancellable.cancel();

      controller.add(2);
      await Future.delayed(Duration.zero);
      expect(reactive.value, 1);

      controller.close();
    });
   group('stateOfAsync Initializers', () {
      test('stateValueOf', () {
        final computer = stateValueOf(42);
        expect(computer(), 42);
      });

      test('stateListOf', () {
        final computer = stateListOf([1, 2, 3]);
        expect(computer(), [1, 2, 3]);
      });

      test('stateMapOf', () {
        final computer = stateMapOf({'a': 1});
        expect(computer(), {'a': 1});
      });

      test('stateSetOf', () {
        final computer = stateSetOf({1});
        expect(computer(), {1});
      });
    });
  });
}
