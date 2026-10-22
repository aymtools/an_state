## 2.0.0

### ⚠️ Major Release / Complete API Redesign

Version `2.0.0` is a major architectural release featuring a complete, end-to-end redesign of the
`an_state` API for enhanced ergonomics, consistency, and alignment across Widgets and ViewModels.

### 🚀 Key Improvements & New Features

- **Streamlined State Initializers**: Introduced `.asStateOf` and `.asStateMutableOf` extension
  getters on values and collections to cleanly instantiate `RStateOf` factories.
- **Unified Factory Functions**: Added top-level factory builders `stateOf`, `stateMutableOf`,
  `stateRefreshableOf`, and `stateRefreshablePagerOf` returning `RStateOf<S>`.
- **ViewModel Lifecycle Binding**: Introduced `state(stateOf)` and `useEffect(action)` extensions on
  `ViewModel` for seamless lifecycle-aware state scoping and side-effect management.
- **Widget State Persistence**: Polished `rememberState(stateOf)` on `BuildContext` for Jetpack
  Compose-like local state persistence.
- **Comprehensive Chinese KDoc & Documentation**: Added thorough documentation and updated all code
  examples across the codebase and README.

### 🔨 Breaking Changes

- Renamed and refactored core extension getters (e.g., replaced legacy `.asStateComputer` with
  `.asStateOf` / `.asStateMutableOf`).
- Streamlined refreshable state extensions, unifying instantiation through `stateRefreshableOf` and
  `stateRefreshablePagerOf` top-level factory functions.
- Stricter type constraints and improved null-safety across all state initializers and reactive
  builders.

## 1.4.2

* Support `FutureOr` return type in `reloader` and `pageLoader` functions for `RefreshableState` and
  `RefreshablePagerState`

## 1.4.1

* Add `autoLoad` parameter (`true`: `reloadData()`, `false`: `refreshData()`, `null`: disable) to
  `RefreshableState` and `RefreshablePagerState`

## 1.4.0

* Add `RefreshableState<T>` for refreshable async data state management with `refreshData()` and
  `reloadData()`
* Add `RefreshablePagerState<T, K, Pager>` for paginated refreshable state management with
  `loadNextPage()`, `refreshData()`, `reloadData()`, and `pages` getter
* Add `rememberRefreshableState` and `rememberRefreshablePagerState` extensions on `BuildContext`
* Add `stateRefreshableOf` and `stateRefreshablePagerOf` extensions on `ViewModel`

## 1.3.1

* Add `asNullableStateOf` extension getter for `Map` and `ValueNotifier`
* Add `nullAsStateOf<T>()` helper function for initializing nullable state with `null`

## 1.3.0

* Add extension getters (`asStateOf`, `asNullableStateOf`) for `Object`, `List`, `Set`, `Map`, and
  `ValueNotifier`
* Refactor `stateOfValueNotifier` parameter from required named parameter to positional parameter
* Upgrade `an_reactive_state` to `^1.2.0`
* Make `cancellable` parameter optional across `BaseState`, `RState`, `ComputedState`, and
  `effect()`

## 1.2.0

* add AsyncDataStateExt
* and listenReactiveStates

## 1.1.0

* add stateOfAsyncData

## 1.0.0

* First version release
