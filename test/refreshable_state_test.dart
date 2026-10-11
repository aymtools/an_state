import 'dart:async';

import 'package:an_async_data/an_async_data.dart';
import 'package:an_pager/an_pager.dart';
import 'package:an_state/an_state.dart';
import 'package:cancellable/cancellable.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RefreshableState', () {
    // 验证初始状态：未指定 initialValue 时默认为 loading，指定时为 data
    test('initialValue default vs specified', () {
      final state1 = RefreshableState<int>(
        reloader: (_) async => 42,
      );
      expect(state1.value, AsyncData<int>.loading());
      expect(state1.isLoading, isTrue);

      final state2 = RefreshableState<int>(
        initialValue: 100,
        reloader: (_) async => 42,
      );
      expect(state2.value, AsyncData<int>.data(100));
      expect(state2.hasData, isTrue);
      expect(state2.data, 100);
    });

    // 验证 refreshData 成功执行时的状态流转
    test('refreshData success path', () async {
      final completer = Completer<int>();
      final state = RefreshableState<int>(
        reloader: (c) => completer.future,
      );

      final future = state.refreshData();
      expect(state.isLoading, isTrue);
      expect(state.value, AsyncData<int>.loading());

      completer.complete(42);
      await future;

      expect(state.hasData, isTrue);
      expect(state.data, 42);
    });

    // 验证 refreshData 执行发生错误时的状态流转
    test('refreshData error path', () async {
      final state = RefreshableState<int>(
        reloader: (_) async => throw Exception('Fetch failed'),
      );

      await state.refreshData();

      expect(state.isError, isTrue);
      expect(state.error, isA<Exception>());
    });

    // 验证并发调用 refreshData 时，会自动取消先前正在执行的任务
    test('refreshData cancels previous running tasks', () async {
      int callCount = 0;
      final completers = <Completer<int>>[Completer<int>(), Completer<int>()];

      final state = RefreshableState<int>(
        reloader: (c) {
          final index = callCount++;
          return completers[index].future;
        },
      );

      final f1 = state.refreshData();
      final f2 = state.refreshData();

      completers[0].complete(111);
      completers[1].complete(222);

      await Future.wait([f1, f2]);

      expect(state.data, 222);
    });

    // 验证 reloadData 在无旧数据与有旧数据时的状态表现
    test('reloadData when initial state is empty vs when state has data', () async {
      final completer1 = Completer<int>();
      final state = RefreshableState<int>(
        reloader: (_) => completer1.future,
      );

      final f1 = state.reloadData();
      expect(state.isLoading, isTrue);

      completer1.complete(10);
      await f1;
      expect(state.data, 10);

      final completer2 = Completer<int>();
      final state2 = RefreshableState<int>(
        initialValue: 10,
        reloader: (_) => completer2.future,
      );

      final f2 = state2.reloadData();
      expect(state2.value, AsyncData<int>.dataLoading(10));
      expect(state2.hasData, isTrue);
      expect(state2.isLoading, isTrue);

      completer2.complete(20);
      await f2;
      expect(state2.data, 20);
    });

    // 验证 reloadData 出错时保留旧数据并设置为 dataError 状态
    test('reloadData error path preserves old data in dataError', () async {
      final state = RefreshableState<int>(
        initialValue: 100,
        reloader: (_) async => throw Exception('Reload error'),
      );

      await state.reloadData();

      expect(state.hasData, isTrue);
      expect(state.isError, isTrue);
      expect(state.data, 100);
      expect(state.error, isA<Exception>());
      expect(state.value, isA<AsyncDataError<int>>());
    });

    // 验证使用外部 Cancellable 控制刷新的取消逻辑
    test('refreshData and reloadData with external cancellable', () async {
      final externalCancellable = Cancellable();
      final completer = Completer<int>();

      final state = RefreshableState<int>(
        reloader: (_) => completer.future,
      );

      final f = state.refreshData(cancellable: externalCancellable);
      externalCancellable.cancel();

      completer.complete(999);
      await f;

      // 由于 Cancellable 已取消，结果不会写入状态
      expect(state.isLoading, isTrue);
    });
  });

  group('RefreshablePagerState', () {
    // 验证分页状态的初始值以及是否指定首页数据
    test('initialValue default vs with first page', () {
      final pagerState1 =
          RefreshablePagerState<String, int, KPage<String, int>>(
        pageLoader: (_, key) async => KPage(
            data: ['a'], hasPrevious: false, hasNext: true, nextPageKey: 1),
      );
      expect(pagerState1.pages, isEmpty);
      expect(pagerState1.value, AsyncData<List<String>>.loading());

      final firstPage = KPage(
          data: ['item1', 'item2'],
          hasPrevious: false,
          hasNext: true,
          nextPageKey: 1);
      final pagerState2 =
          RefreshablePagerState<String, int, KPage<String, int>>(
        pageLoader: (_, key) async => KPage(
            data: ['a'], hasPrevious: false, hasNext: true, nextPageKey: 2),
        first: firstPage,
      );
      expect(pagerState2.pages, isEmpty);
      expect(pagerState2.data, ['item1', 'item2']);
    });

    // 验证分页刷新成功加载第一页并填充 pages 列表
    test('refreshData loads first page and populates pages', () async {
      final pagerState =
          RefreshablePagerState<String, int, KPage<String, int>>(
        pageLoader: (can, key) async {
          expect(key, isNull);
          return KPage(
              data: ['p1_item1', 'p1_item2'],
              hasPrevious: false,
              hasNext: true,
              nextPageKey: 1);
        },
      );

      await pagerState.refreshData();

      expect(pagerState.pages.length, 1);
      expect(pagerState.pages.first.nextPageKey, 1);
      expect(pagerState.data, ['p1_item1', 'p1_item2']);
    });

    // 验证 loadNextPage 成功加载下一页并追加到数据列表
    test('loadNextPage appends new page data', () async {
      final pagerState =
          RefreshablePagerState<String, int, KPage<String, int>>(
        pageLoader: (can, key) async {
          if (key == null) {
            return KPage(
                data: ['p1_1', 'p1_2'],
                hasPrevious: false,
                hasNext: true,
                nextPageKey: 1);
          } else if (key == 1) {
            return KPage(
                data: ['p2_1', 'p2_2'],
                hasPrevious: true,
                hasNext: false,
                nextPageKey: 2);
          }
          throw Exception('Unexpected key $key');
        },
      );

      await pagerState.refreshData();
      expect(pagerState.data, ['p1_1', 'p1_2']);

      await pagerState.loadNextPage();
      expect(pagerState.pages.length, 2);
      expect(pagerState.data, ['p1_1', 'p1_2', 'p2_1', 'p2_2']);
    });

    // 验证 loadNextPage 发生异常时的错误处理逻辑
    test('loadNextPage error handling', () async {
      final pagerState =
          RefreshablePagerState<String, int, KPage<String, int>>(
        pageLoader: (can, key) async {
          if (key == null) {
            return KPage(
                data: ['p1'],
                hasPrevious: false,
                hasNext: true,
                nextPageKey: 1);
          }
          throw Exception('Next page failed');
        },
      );

      await pagerState.refreshData();
      expect(pagerState.data, ['p1']);

      expect(
        () async => await pagerState.loadNextPage(),
        throwsA(isA<Exception>()),
      );

      expect(pagerState.data, ['p1']);
      expect(pagerState.pages.length, 1);
    });

    // 验证 reloadData 重新加载首页并清空历史 pages
    test('reloadData reloads first page and clears previous pages', () async {
      int fetchCount = 0;
      final pagerState =
          RefreshablePagerState<String, int, KPage<String, int>>(
        pageLoader: (can, key) async {
          fetchCount++;
          if (fetchCount == 1) {
            return KPage(
                data: ['v1_1'],
                hasPrevious: false,
                hasNext: true,
                nextPageKey: 1);
          } else {
            return KPage(
                data: ['v2_1', 'v2_2'],
                hasPrevious: false,
                hasNext: true,
                nextPageKey: 10);
          }
        },
      );

      await pagerState.refreshData();
      expect(pagerState.data, ['v1_1']);
      expect(pagerState.pages.length, 1);

      await pagerState.reloadData();
      expect(pagerState.data, ['v2_1', 'v2_2']);
      expect(pagerState.pages.length, 1);
      expect(pagerState.pages.first.nextPageKey, 10);
    });

    // 验证分页 refreshData 异常时的错误处理
    test('refreshData error state in pager', () async {
      final pagerState =
          RefreshablePagerState<String, int, KPage<String, int>>(
        pageLoader: (_, __) async => throw Exception('Pager refresh error'),
      );

      await pagerState.refreshData();

      expect(pagerState.isError, isTrue);
      expect(pagerState.error, isA<Exception>());
      expect(pagerState.pages, isEmpty);
    });

    // 验证分页 reloadData 异常时保留旧数据并设为 dataError
    test('reloadData error state in pager preserves data in dataError', () async {
      int count = 0;
      final pagerState =
          RefreshablePagerState<String, int, KPage<String, int>>(
        pageLoader: (_, __) async {
          count++;
          if (count == 1) {
            return KPage(
                data: ['item'],
                hasPrevious: false,
                hasNext: true,
                nextPageKey: 1);
          }
          throw Exception('Reload failed');
        },
      );

      await pagerState.refreshData();
      expect(pagerState.data, ['item']);

      await pagerState.reloadData();
      expect(pagerState.hasData, isTrue);
      expect(pagerState.isError, isTrue);
      expect(pagerState.data, ['item']);
      expect(pagerState.error, isA<Exception>());
    });
  });
}
