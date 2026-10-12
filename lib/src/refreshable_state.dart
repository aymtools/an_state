import 'dart:async';

import 'package:an_pager/an_pager.dart';
import 'package:an_reactive_state/an_reactive_state.dart';
import 'package:an_state/src/async_data_state_ext.dart';
import 'package:an_state/src/remember_state_ext.dart';
import 'package:an_state/src/tools.dart';
import 'package:an_viewmodel/an_viewmodel.dart';
import 'package:cancellable/cancellable.dart';
import 'package:flutter/widgets.dart';
import 'package:remember/remember.dart';

/// 可刷新的响应式状态类，封装了异步数据 [AsyncData] 的刷新和重新加载操作。
///
/// 适用于需要支持下拉刷新、重新加载等功能的异步数据状态管理。
class RefreshableState<T> extends RState<AsyncData<T>> {
  /// 数据加载器函数，用于异步获取数据。
  final Future<T> Function(Cancellable) _reloader;

  /// 用于取消当前重新加载任务的可取消句柄。
  Cancellable? _reloading;

  /// 用于取消当前刷新任务的可取消句柄。
  Cancellable? _refreshing;

  /// 用于取消当前加载任务的可取消句柄。
  Cancellable? _loading;

  /// 创建一个 [RefreshableState] 实例。
  ///
  /// [initialValue] 为初始数据值；若未提供，则状态默认为 [AsyncData.loading]。
  /// [reloader] 为异步数据加载逻辑。
  /// [cancellable] 可选的取消句柄，绑定当前状态的生命周期。
  /// [equals] 可选的状态值相等性比较器。
  /// [autoLoad] 是否自动加载数据，默认为 `true`。[true]: 重新加载数据；[false]: 刷新数据；[null]: 不自动加载。
  RefreshableState({
    T? initialValue,
    required Future<T> Function(Cancellable) reloader,
    super.cancellable,
    super.equals,
    bool? autoLoad = true,
  })  : _reloader = reloader,
        super(
            initialValue: initialValue == null
                ? AsyncData<T>.loading()
                : AsyncData<T>.data(initialValue)) {
    if (autoLoad == true) {
      Future.microtask(reloadData);
    } else if (autoLoad == false) {
      Future.microtask(refreshData);
    }
  }

  /// 重新刷新整个内容，清理旧数据。
  ///
  /// 将状态切换为 [AsyncData.loading]，并重新执行 [_reloader]。
  /// [cancellable] 可选的取消句柄，用于取消本次刷新操作。
  Future<void> refreshData({Cancellable? cancellable}) async {
    _reloading?.cancel();
    _refreshing?.cancel();
    _loading?.cancel();
    final loading = makeLiveCancellable(other: cancellable);
    toLoading();
    _refreshing = loading;
    try {
      final result = await _reloader(loading);
      if (loading.isAvailable) {
        toData(result);
      }
    } catch (e, st) {
      if (loading.isAvailable) {
        toError(e, st);
      }
    } finally {
      loading.cancel();
    }
  }

  /// 重新加载内容，如果有旧数据则保留旧数据。
  ///
  /// 将状态切换为带有旧数据的加载状态（[AsyncData.dataLoading]），并重新执行 [_reloader]。
  /// [cancellable] 可选的取消句柄，用于取消本次重新加载操作。
  Future<void> reloadData({Cancellable? cancellable}) async {
    _reloading?.cancel();
    _refreshing?.cancel();
    _loading?.cancel();
    final loading = makeLiveCancellable(other: cancellable);
    toDataLoading();
    _reloading = loading;
    try {
      final result = await _reloader(loading);
      if (loading.isAvailable) {
        toData(result);
      }
    } catch (e, st) {
      if (loading.isAvailable) {
        toDataError(e, st);
      }
    } finally {
      loading.cancel();
    }
  }
}

/// 支持分页加载的可刷新响应式状态类。
///
/// 继承自 [RefreshableState]，专门用于管理基于 [BasePager] 的分页列表数据。
class RefreshablePagerState<T, K, P extends BasePager<T, K, P>>
    extends RefreshableState<List<T>> {
  /// 已加载的所有页面数据列表。
  final List<P> _pages = [];

  /// 分页数据加载器函数，接收可取消句柄和下一页的 Key。
  final Future<P> Function(Cancellable, K? nextPageKey) _pageLoader;

  /// 获取当前已加载的所有页面对象列表。
  List<P> get pages => _pages;

  /// 创建一个 [RefreshablePagerState] 实例。
  ///
  /// [pageLoader] 为分页数据加载逻辑。
  /// [first] 可选的首页数据。
  /// [cancellable] 可选的取消句柄。
  /// [equals] 可选的状态值相等性比较器。
  /// [autoLoad] 是否自动加载首页数据，默认为 `true`。[true]: 重新加载数据；[false]: 刷新数据；[null]: 不自动加载。
  RefreshablePagerState({
    required Future<P> Function(Cancellable, K?) pageLoader,
    P? first,
    super.cancellable,
    super.equals,
    super.autoLoad = true,
  })  : _pageLoader = pageLoader,
        super(
            reloader: (_) async => Completer<List<T>>().future,
            initialValue: first?.data);

  /// 加载下一页数据。
  ///
  /// 根据最后一页的 [BasePager.nextPageKey] 获取下一页数据并追加到当前列表中。
  /// [cancellable] 可选的取消句柄，用于取消本次加载下一页操作。
  Future<void> loadNextPage({Cancellable? cancellable}) async {
    _reloading?.cancel();
    _refreshing?.cancel();
    _loading?.cancel();
    final loading = makeLiveCancellable(other: cancellable);
    _loading = loading;
    try {
      final page = await _pageLoader(loading, _pages.lastOrNull?.nextPageKey);
      if (loading.isUnavailable) return;
      _pages.add(page);
      if (isData) {
        data.addAll(page.data);
        refresh();
      } else {
        toData(page.data);
      }
    } catch (e) {
      if (loading.isAvailable) {
        rethrow;
      }
    } finally {
      loading.cancel();
    }
  }

  /// 重新刷新整个内容，清理旧页面和旧数据。
  ///
  /// 清空现有已加载的 [_pages]，将状态切换为 [AsyncData.loading]，并重新加载第一页。
  /// [cancellable] 可选的取消句柄，用于取消本次刷新操作。
  @override
  Future<void> refreshData({Cancellable? cancellable}) async {
    _reloading?.cancel();
    _refreshing?.cancel();
    _loading?.cancel();
    final loading = makeLiveCancellable(other: cancellable);
    _pages.clear();
    toLoading();
    _refreshing = loading;
    try {
      final result = await _pageLoader(loading, null);
      if (loading.isAvailable) {
        _pages.add(result);
        toData(result.data);
      }
    } catch (e, st) {
      if (loading.isAvailable) {
        toError(e, st);
      }
    } finally {
      loading.cancel();
    }
  }

  /// 重新加载内容，保留现有旧数据直到新数据加载完成。
  ///
  /// 将状态切换为 [AsyncData.dataLoading]，重新加载第一页数据，并在成功后替换旧数据。
  /// [cancellable] 可选的取消句柄，用于取消本次重新加载操作。
  @override
  Future<void> reloadData({Cancellable? cancellable}) async {
    _reloading?.cancel();
    _refreshing?.cancel();
    _loading?.cancel();
    final loading = makeLiveCancellable(other: cancellable);
    toDataLoading();
    _reloading = loading;
    try {
      final result = await _pageLoader(loading, null);
      if (loading.isAvailable) {
        _pages.clear();
        _pages.add(result);
        toData(result.data);
      }
    } catch (e, st) {
      if (loading.isAvailable) {
        toDataError(e, st);
      }
    } finally {
      loading.cancel();
    }
  }
}

extension RememberRefreshableStateExt on BuildContext {
  /// 在 Widget 树中记住一个可刷新的响应式状态 [RefreshableState]。
  RefreshableState<T> rememberRefreshableState<T>(
    Future<T> Function(Cancellable) reloader, {
    T? initialValue,
    RStateEquality<AsyncData<T>>? equals,
    bool? autoLoad = true,
    String? debugLabel,
    bool listen = true,
  }) =>
      remember<RefreshableState<T>>(
        factory3: (l, c) {
          return RefreshableState<T>(
              reloader: reloader,
              initialValue: initialValue,
              cancellable: c,
              equals: equals,
              autoLoad: autoLoad);
        },
        onCreate: listen ? onCreateListen : null,
        key: 'rememberRefreshableState',
      );

  /// 在 Widget 树中记住一个可刷新的分页响应式状态 [RefreshablePagerState]。
  RefreshablePagerState<T, K, P>
      rememberRefreshablePagerState<T, K, P extends BasePager<T, K, P>>(
    Future<P> Function(Cancellable, K?) pageLoader, {
    P? first,
    RStateEquality<AsyncData<List<T>>>? equals,
    bool? autoLoad = true,
    String? debugLabel,
    bool listen = true,
  }) {
    return remember<RefreshablePagerState<T, K, P>>(
      factory3: (l, c) {
        return RefreshablePagerState<T, K, P>(
            pageLoader: pageLoader,
            first: first,
            cancellable: c,
            equals: equals,
            autoLoad: autoLoad);
      },
      onCreate: listen ? onCreateListen : null,
      key: 'rememberRefreshablePagerState',
    );
  }
}

extension ViewmodelRefreshableStateExt on ViewModel {
  /// 在 ViewModel 中创建一个可刷新的响应式状态 [RefreshableState]。
  RefreshableState<T> stateRefreshableOf<T>(
    Future<T> Function(Cancellable) reloader, {
    T? initialValue,
    RStateEquality<AsyncData<T>>? equals,
  }) =>
      RefreshableState<T>(
          reloader: reloader,
          initialValue: initialValue,
          cancellable: makeLiveCancellable(),
          equals: equals);

  /// 在 ViewModel 中创建一个可刷新的分页响应式状态 [RefreshablePagerState]。
  RefreshablePagerState<T, K, P>
      stateRefreshablePagerOf<T, K, P extends BasePager<T, K, P>>(
    Future<P> Function(Cancellable, K?) pageLoader, {
    P? first,
    RStateEquality<AsyncData<List<T>>>? equals,
  }) =>
          RefreshablePagerState<T, K, P>(
              pageLoader: pageLoader,
              first: first,
              cancellable: makeLiveCancellable(),
              equals: equals);
}
