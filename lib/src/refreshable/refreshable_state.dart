import 'dart:async';

import 'package:an_pager/an_pager.dart';
import 'package:an_reactive_state/an_reactive_state.dart';
import 'package:an_state/src/ext/async_data_state_ext.dart';
import 'package:an_state/src/ext/remember_state_ext.dart';
import 'package:an_state/src/tools.dart';
import 'package:an_viewmodel/an_viewmodel.dart';
import 'package:cancellable/cancellable.dart';
import 'package:flutter/widgets.dart';
import 'package:remember/remember.dart';

/// 可刷新的响应式状态类，封装了异步数据 [AsyncData] 的刷新和重新加载操作。
///
/// 继承自 [RState<AsyncData<T>>]，适用于需要支持下拉刷新、带旧数据加载指示、重新加载等功能的界面数据状态管理。
class RefreshableState<T> extends RState<AsyncData<T>> {
  /// 数据加载器函数，用于获取数据。
  final FutureOr<T> Function(Cancellable) _reloader;

  /// 用于取消当前重新加载任务的可取消句柄。
  Cancellable? _reloading;

  /// 用于取消当前刷新任务的可取消句柄。
  Cancellable? _refreshing;

  /// 用于取消当前加载任务的可取消句柄。
  Cancellable? _loading;

  /// 创建一个 [RefreshableState] 实例。
  ///
  /// [initialValue] 为初始数据值；若未提供，则初始状态默认为 [AsyncData.loading]。
  /// [reloader] 为异步数据加载逻辑，属于独立的异步任务，不会与其他 `state.value` 自动建立响应式联动。
  /// [cancellable] 可选的取消句柄，用于绑定当前状态的生命周期。
  /// [equals] 可选的状态值相等性比较器。
  /// [autoLoad] 是否在初始化时自动加载数据，默认为 `true`：
  /// - `true`: 在微任务中自动调用 [reloadData]（保留旧数据加载模式）；
  /// - `false`: 在微任务中自动调用 [refreshData]（清空旧数据刷新模式）；
  /// - `null`: 不自动加载，需后续手动触发。
  RefreshableState({
    T? initialValue,
    required FutureOr<T> Function(Cancellable) reloader,
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
  /// 先将状态切换为纯加载中状态 [AsyncData.loading]，并重新执行 [_reloader]。
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
  /// 先将状态切换为带有旧数据的加载状态（[AsyncData.dataLoading]），并重新执行 [_reloader]。
  /// 加载成功后更新数据为 [AsyncData.data]，如果失败则转换为带有旧数据的错误状态 [AsyncData.dataError]。
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
/// - [T]: 列表中单个元素的数据类型。
/// - [K]: 分页 Key 的类型（如页码 `int` 或游标 `String`）。
/// - [P]: 继承自 [BasePager<T, K, P>] 的具体分页响应对象类型。
class RefreshablePagerState<T, K, P extends BasePager<T, K, P>>
    extends RefreshableState<List<T>> {
  /// 已加载的所有页面数据列表。
  final List<P> _pages = [];

  /// 分页数据加载器函数，接收可取消句柄和下一页的 Key。
  final FutureOr<P> Function(Cancellable, K? nextPageKey) _pageLoader;

  /// 获取当前已加载的所有页面对象 [BasePager] 列表。
  List<P> get pages => _pages;

  /// 创建一个 [RefreshablePagerState] 实例。
  ///
  /// [pageLoader] 为分页数据加载逻辑，属于独立的异步任务，不会与其他 `state.value` 自动建立响应式联动。
  /// [first] 可选的首页数据。
  /// [cancellable] 可选的生命周期取消句柄。
  /// [equals] 可选的状态值相等性比较器。
  /// [autoLoad] 是否在初始化时自动加载首页数据，默认为 `true`：
  /// - `true`: 重新加载首页数据；
  /// - `false`: 刷新首页数据；
  /// - `null`: 不自动加载。
  RefreshablePagerState({
    required FutureOr<P> Function(Cancellable, K?) pageLoader,
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
  /// 根据最后一页的 [BasePager.nextPageKey] 获取下一页数据，并将其追加到当前列表末尾。
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

  /// 重新刷新整个分页内容，清理所有旧页面和旧数据。
  ///
  /// 清空已有页面 [_pages]，将状态切换为 [AsyncData.loading]，并重新加载第一页数据。
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

  /// 重新加载第一页内容，保留现有数据直到新数据请求完成。
  ///
  /// 将状态切换为 [AsyncData.dataLoading]，重新加载第一页数据，并在成功后替换现有页面列表与数据。
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

/// 创建一个可刷新响应式状态 [RefreshableState] 的工厂函数。
///
/// 返回一个 [RStateOf<RefreshableState<T>>] 状态定义工厂，可配合 `state(...)` 或 `context.rememberState(...)` 使用。
///
/// [reloader] 异步数据加载逻辑函数，接收可取消句柄 [Cancellable]。
/// [initialValue] 可选的初始数据值；若不提供则默认为加载中状态。
/// [equals] 可选的状态值相等性比较器。
/// [autoLoad] 是否在初始化时自动触发加载。
/// [debugLabel] 可选的调试标签。
RStateOf<RefreshableState<T>> stateRefreshableOf<T>(
  FutureOr<T> Function(Cancellable) reloader, {
  T? initialValue,
  RStateEquality<AsyncData<T>>? equals,
  bool? autoLoad = true,
  String? debugLabel,
}) =>
    (cancellable) => RefreshableState<T>(
        reloader: reloader,
        initialValue: initialValue,
        cancellable: cancellable,
        equals: equals,
        autoLoad: autoLoad);

/// 创建一个支持分页加载的可刷新响应式状态 [RefreshablePagerState] 的工厂函数。
///
/// 返回一个 [RStateOf<RefreshablePagerState<T, K, P>>] 状态定义工厂，可配合 `state(...)` 或 `context.rememberState(...)` 使用。
///
/// [pageLoader] 分页数据加载逻辑函数，接收可取消句柄 [Cancellable] 与下一页的 Key。
/// [first] 可选的首页预加载分页数据。
/// [equals] 可选的状态值相等性比较器。
/// [autoLoad] 是否在初始化时自动触发首页加载。
/// [debugLabel] 可选的调试标签。
RStateOf<RefreshablePagerState<T, K, P>>
    stateRefreshablePagerOf<T, K, P extends BasePager<T, K, P>>(
  FutureOr<P> Function(Cancellable, K?) pageLoader, {
  P? first,
  RStateEquality<AsyncData<List<T>>>? equals,
  bool? autoLoad = true,
  String? debugLabel,
}) =>
        (cancellable) => RefreshablePagerState<T, K, P>(
            pageLoader: pageLoader,
            first: first,
            cancellable: cancellable,
            equals: equals,
            autoLoad: autoLoad);

