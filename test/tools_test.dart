import 'dart:async';

import 'package:an_async_data/an_async_data.dart';
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

    test('valueNotifierComputation should observe changes', () {
      final notifier = ValueNotifier(0);
      int computeCount = 0;
      final computer = valueNotifierComputation(notifier);
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

    test('changeNotifierComputation should observe changes', () {
      final notifier = ValueNotifier(0); // ValueNotifier is a ChangeNotifier
      int computeCount = 0;
      final computer = changeNotifierComputation(
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

    test('asyncComputation (Future) should observe changes', () async {
      final completer = Completer<int>();
      int computeCount = 0;
      final computer = asyncComputation(
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

    test('asyncComputation (Future Error) should handle error', () async {
      final completer = Completer<int>();
      Object? capturedError;
      final computer = asyncComputation<int>(
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

    test('asyncComputation (Stream) should observe changes', () async {
      final controller = StreamController<int>();
      int computeCount = 0;
      final computer = asyncComputation(
        stream: controller.stream,
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

    test('asyncComputation (Stream Error) should handle error', () async {
      final controller = StreamController<int>();
      Object? capturedError;
      final computer = asyncComputation<int>(
        stream: controller.stream,
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

    test('asyncComputation (Stream cancelOnError: true)', () async {
      final controller = StreamController<int>();
      int errorCount = 0;
      final computer = asyncComputation<int>(
        stream: controller.stream,
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

    test('asyncComputation onError signatures', () async {
      final c1 = Completer<int>();
      final comp1 = asyncComputation<int>(
          future: c1.future, initialValue: 0, onError: () => 1);
      final r1 = ComputedState(
        computer: () => comp1(),
        cancellable: Cancellable(),
      );
      expect(r1.value, 0); // Start subscription

      final c2 = Completer<int>();
      final comp2 = asyncComputation<int>(
          future: c2.future, initialValue: 0, onError: (e) => 2);
      final r2 = ComputedState(
        computer: () => comp2(),
        cancellable: Cancellable(),
      );
      expect(r2.value, 0); // Start subscription

      final c3 = Completer<int>();
      final comp3 = asyncComputation<int>(
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

    test('asyncComputation with already completed future', () async {
      final completer = Completer<int>()..complete(42);
      final computer = asyncComputation<int>(
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

    test('asyncComputation outside of reactive context should not subscribe',
        () async {
      final controller = StreamController<int>();
      final computer = asyncComputation<int>(
        stream: controller.stream,
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

    test(
        'asyncComputation should return current value without triggering new subscriptions',
        () async {
      final controller = StreamController<int>();
      final computer = asyncComputation<int>(
        stream: controller.stream,
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

    test('asyncComputation should cancel subscription when context is disposed',
        () async {
      final controller = StreamController<int>();
      int computeCount = 0;
      final cancellable = Cancellable();

      final computer = asyncComputation(
        stream: controller.stream,
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

    test('asyncComputation with explicit cancellable', () async {
      final controller = StreamController<int>();
      final manualCancellable = Cancellable();

      final computer = asyncComputation(
        stream: controller.stream,
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
    group('extension getters', () {
      /// 验证各种对象、集合及 ValueNotifier 的 asStateComputation 与 asNullableStateComputation 扩展方法
      test('asStateComputation and asNullableStateComputation', () {
        // 验证数字与可空数字的状态计算器
        expect(42.asStateComputation(), 42);
        expect(42.asNullableStateComputation(), 42);

        // 验证列表与可空列表的状态计算器
        final list = [1, 2, 3];
        expect(list.asStateComputation(), [1, 2, 3]);
        expect(list.asNullableStateComputation(), [1, 2, 3]);

        // 验证集合与可空集合的状态计算器
        final set = {1, 2};
        expect(set.asStateComputation(), {1, 2});
        expect(set.asNullableStateComputation(), {1, 2});

        // 验证映射与可空映射的状态计算器
        final map = {'a': 1};
        expect(map.asStateComputation(), {'a': 1});
        expect(map.asNullableStateComputation(), {'a': 1});

        // 验证 ValueNotifier 的 asStateComputation 扩展转换
        final notifier = ValueNotifier(10);
        final computer = notifier.asStateComputation;
        expect(computer(), 10);
        final nullableComputer = notifier.asNullableStateComputation;
        expect(nullableComputer(), 10);

        // 验证 nullAsStateComputation 辅助方法
        final nullComputer = nullAsStateComputation<int>();
        expect(nullComputer(), isNull);
      });
    });

    group('stateOfAsyncData', () {
      test('initialValue default vs custom', () {
        final comp1 = asyncDataComputation<int>();
        final r1 = ComputedState(
          computer: () => comp1(),
          cancellable: Cancellable(),
        );
        expect(r1.value, AsyncData<int>.loading());

        final comp2 = asyncDataComputation<int>(initialValue: 10);
        final r2 = ComputedState(
          computer: () => comp2(),
          cancellable: Cancellable(),
        );
        expect(r2.value, AsyncData<int>.data(10));
      });

      test('Future, fFactory, fFactory2', () async {
        final completer = Completer<int>();
        final compFuture = asyncDataComputation<int>(future: completer.future);
        final rFuture = ComputedState(
          computer: () => compFuture(),
          cancellable: Cancellable(),
        );

        expect(rFuture.value, AsyncData<int>.loading());
        completer.complete(42);
        await Future.delayed(Duration.zero);
        expect(rFuture.value, AsyncData<int>.data(42));

        final compFactory = asyncDataComputation<int>(
          fFactory: () => Future.value(100),
        );
        final rFactory = ComputedState(
          computer: () => compFactory(),
          cancellable: Cancellable(),
        );
        expect(rFactory.value, AsyncData<int>.loading());
        await Future.delayed(Duration.zero);
        expect(rFactory.value, AsyncData<int>.data(100));

        Cancellable? capturedCancellable;
        final compFactory2 = asyncDataComputation<int>(
          fFactory2: (can) {
            capturedCancellable = can;
            return Future.value(200);
          },
        );
        final rFactory2 = ComputedState(
          computer: () => compFactory2(),
          cancellable: Cancellable(),
        );
        expect(rFactory2.value, AsyncData<int>.loading());
        await Future.delayed(Duration.zero);
        expect(rFactory2.value, AsyncData<int>.data(200));
        expect(capturedCancellable, isNotNull);
      });

      test('Future Error and onError', () async {
        final completer1 = Completer<int>();
        final comp1 = asyncDataComputation<int>(future: completer1.future);
        final r1 = ComputedState(
          computer: () => comp1(),
          cancellable: Cancellable(),
        );
        expect(r1.value, AsyncData<int>.loading());

        completer1.completeError('test error');
        await Future.delayed(Duration.zero);
        expect(r1.value, isA<AsyncDataError<int>>());
        expect((r1.value as AsyncDataError<int>).error, 'test error');

        final completer2 = Completer<int>();
        final comp2 = asyncDataComputation<int>(
          future: completer2.future,
          onError: (e) => -1,
        );
        final r2 = ComputedState(
          computer: () => comp2(),
          cancellable: Cancellable(),
        );
        expect(r2.value, AsyncData<int>.loading());

        completer2.completeError('error');
        await Future.delayed(Duration.zero);
        expect(r2.value, AsyncData<int>.data(-1));

        final completer3 = Completer<int>();
        final comp3 = asyncDataComputation<int>(
          future: completer3.future,
          onError: (e) => throw 'error in onError',
        );
        final r3 = ComputedState(
          computer: () => comp3(),
          cancellable: Cancellable(),
        );
        expect(r3.value, AsyncData<int>.loading());

        completer3.completeError('original error');
        await Future.delayed(Duration.zero);
        expect(r3.value, isA<AsyncDataError<int>>());
        expect((r3.value as AsyncDataError<int>).error, 'error in onError');
      });

      test('Stream, sFactory, sFactory2', () async {
        final controller = StreamController<int>();
        final compStream = asyncDataComputation<int>(stream: controller.stream);
        final rStream = ComputedState(
          computer: () => compStream(),
          cancellable: Cancellable(),
        );
        expect(rStream.value, AsyncData<int>.loading());

        controller.add(1);
        await Future.delayed(Duration.zero);
        expect(rStream.value, AsyncData<int>.data(1));

        controller.add(2);
        await Future.delayed(Duration.zero);
        expect(rStream.value, AsyncData<int>.data(2));

        controller.close();

        final sController = StreamController<int>();
        final compSFactory = asyncDataComputation<int>(
          sFactory: () => sController.stream,
        );
        final rSFactory = ComputedState(
          computer: () => compSFactory(),
          cancellable: Cancellable(),
        );
        expect(rSFactory.value, AsyncData<int>.loading());

        sController.add(10);
        await Future.delayed(Duration.zero);
        expect(rSFactory.value, AsyncData<int>.data(10));
        sController.close();

        final s2Controller = StreamController<int>();
        Cancellable? capturedCancellable;
        final compSFactory2 = asyncDataComputation<int>(
          sFactory2: (can) {
            capturedCancellable = can;
            return s2Controller.stream;
          },
        );
        final rSFactory2 = ComputedState(
          computer: () => compSFactory2(),
          cancellable: Cancellable(),
        );
        expect(rSFactory2.value, AsyncData<int>.loading());

        s2Controller.add(20);
        await Future.delayed(Duration.zero);
        expect(rSFactory2.value, AsyncData<int>.data(20));
        expect(capturedCancellable, isNotNull);
        s2Controller.close();
      });

      test('Stream Error and cancelOnError', () async {
        final controller = StreamController<int>();
        final comp = asyncDataComputation<int>(
          stream: controller.stream,
          cancelOnError: true,
        );
        final r = ComputedState(
          computer: () => comp(),
          cancellable: Cancellable(),
        );
        expect(r.value, AsyncData<int>.loading());

        controller.add(1);
        await Future.delayed(Duration.zero);
        expect(r.value, AsyncData<int>.data(1));

        controller.addError('stream error');
        await Future.delayed(Duration.zero);
        expect(r.value, isA<AsyncDataError<int>>());
        expect((r.value as AsyncDataError<int>).error, 'stream error');

        controller.add(2);
        await Future.delayed(Duration.zero);
        // Because cancelOnError is true, value should remain error
        expect((r.value as AsyncDataError<int>).error, 'stream error');

        controller.close();
      });

      test('onError signatures', () async {
        final c1 = Completer<int>();
        final comp1 = asyncDataComputation<int>(
          future: c1.future,
          onError: () => 1,
        );
        final r1 = ComputedState(
          computer: () => comp1(),
          cancellable: Cancellable(),
        );
        expect(r1.value, AsyncData<int>.loading());

        final c2 = Completer<int>();
        final comp2 = asyncDataComputation<int>(
          future: c2.future,
          onError: (e) => 2,
        );
        final r2 = ComputedState(
          computer: () => comp2(),
          cancellable: Cancellable(),
        );
        expect(r2.value, AsyncData<int>.loading());

        final c3 = Completer<int>();
        final comp3 = asyncDataComputation<int>(
          future: c3.future,
          onError: (e, s) => 3,
        );
        final r3 = ComputedState(
          computer: () => comp3(),
          cancellable: Cancellable(),
        );
        expect(r3.value, AsyncData<int>.loading());

        c1.completeError('e');
        c2.completeError('e');
        c3.completeError('e');

        await Future.delayed(Duration.zero);

        expect(r1.value, AsyncData<int>.data(1));
        expect(r2.value, AsyncData<int>.data(2));
        expect(r3.value, AsyncData<int>.data(3));
      });

      test('explicit cancellable and context disposal', () async {
        final controller = StreamController<int>();
        final manualCancellable = Cancellable();

        final comp = asyncDataComputation<int>(
          stream: controller.stream,
          cancellable: manualCancellable,
        );

        final r = ComputedState(
          computer: () => comp(),
          cancellable: Cancellable(),
        );

        expect(r.value, AsyncData<int>.loading());

        controller.add(1);
        await Future.delayed(Duration.zero);
        expect(r.value, AsyncData<int>.data(1));

        manualCancellable.cancel();

        controller.add(2);
        await Future.delayed(Duration.zero);
        expect(r.value, AsyncData<int>.data(1));

        controller.close();
      });
    });
  });
}
