import 'package:an_async_data/an_async_data.dart';
import 'package:an_state/an_state.dart';
import 'package:cancellable/cancellable.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AsyncDataStateExt', () {
    test('Getters work correctly for loading, data, and error states', () {
      final state = RState<AsyncData<int>>(
        initialValue: AsyncData<int>.loading(),
        cancellable: Cancellable(),
      );

      // Loading state
      expect(state.isLoading, isTrue);
      expect(state.isError, isFalse);
      expect(state.isData, isFalse);
      expect(state.hasData, isFalse);
      expect(state.dataOrNull, isNull);
      expect(() => state.data, throwsStateError);
      expect(() => state.error, throwsStateError);
      expect(state.stackTrace, isNull);

      // Data state
      state.toData(42);
      expect(state.isLoading, isFalse);
      expect(state.isError, isFalse);
      expect(state.isData, isTrue);
      expect(state.hasData, isTrue);
      expect(state.data, 42);
      expect(state.dataOrNull, 42);
      expect(() => state.error, throwsStateError);

      // Error state
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

    test('toLoading, toData, and toError update state and trigger reactivity',
        () {
      final state = RState<AsyncData<String>>(
        initialValue: AsyncData<String>.loading(),
        cancellable: Cancellable(),
      );
      int computeCount = 0;

      final computed = ComputedState(
        computer: () {
          computeCount++;
          return state.value;
        },
        cancellable: Cancellable(),
      );

      expect(computed.value, AsyncData<String>.loading());
      expect(computeCount, 1);

      state.toData('hello');
      expect(computed.value, AsyncData<String>.data('hello'));
      expect(computeCount, 2);

      final st = StackTrace.current;
      state.toError('err', st);
      expect(computed.value, AsyncData<String>.error('err', st));
      expect(computeCount, 3);

      state.toLoading();
      expect(computed.value, AsyncData<String>.loading());
      expect(computeCount, 4);
    });

    test('toDataLoading when hasData is true vs false', () {
      final state = RState<AsyncData<int>>(
        initialValue: AsyncData<int>.loading(),
        cancellable: Cancellable(),
      );

      // When hasData is false, toDataLoading transitions to standard loading
      state.toDataLoading();
      expect(state.value, AsyncData<int>.loading());
      expect(state.hasData, isFalse);

      // Transition to data state
      state.toData(100);
      expect(state.hasData, isTrue);
      expect(state.data, 100);

      // When hasData is true, toDataLoading transitions to dataLoading(100)
      state.toDataLoading();
      expect(state.value, AsyncData<int>.dataLoading(100));
      expect(state.hasData, isTrue);
      expect(state.isLoading, isTrue);

      // Calling toDataLoading while already in dataLoading preserves existing inner data
      state.toDataLoading();
      expect(state.value, AsyncData<int>.dataLoading(100));
      expect(state.hasData, isTrue);
    });

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

    test('toDataError when hasData is true vs false', () {
      final state = RState<AsyncData<int>>(
        initialValue: AsyncData<int>.loading(),
        cancellable: Cancellable(),
      );
      final st = StackTrace.current;

      // When hasData is false, toDataError transitions to standard error
      state.toDataError('err1', st);
      expect(state.value, AsyncData<int>.error('err1', st));
      expect(state.hasData, isFalse);
      expect(state.isError, isTrue);

      // Transition to data state
      state.toData(200);
      expect(state.hasData, isTrue);

      // When hasData is true, toDataError transitions to dataError(200, 'err2', st)
      state.toDataError('err2', st);
      expect(state.value, AsyncData<int>.dataError(200, 'err2', st));
      expect(state.hasData, isTrue);
      expect(state.isError, isTrue);

      // Transition from dataError back to dataLoading via toDataLoading
      state.toDataLoading();
      expect(state.value, AsyncData<int>.dataLoading(200));
      expect(state.hasData, isTrue);
    });

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
