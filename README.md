# an_state

`an_state` is a powerful, lightweight reactive state management library for Flutter. It seamlessly
integrates the high-performance reactive engine
of [an_reactive_state](https://pub.dev/packages/an_reactive_state), the robust lifecycle management
of [an_viewmodel](https://pub.dev/packages/an_viewmodel), and the elegant state persistence
of [remember](https://pub.dev/packages/remember).

> [!IMPORTANT]
> `an_state` **strongly depends** on [anlifecycle](https://pub.dev/packages/anlifecycle). All core
> features, including `rememberState`, `state(...)`, and `context.viewModels()`, require a
> valid `Lifecycle` context provided within the widget tree.

---

## 🚀 Key Features

- **🎯 Transparent Reactivity**: Based on `an_reactive_state`, UI updates automatically when state
  changes. No `notifyListeners()` or `setState()` required.
- **🧬 Lifecycle-Aware**: States are bound to the lifecycle of ViewModels or Widgets, ensuring zero
  memory leaks through automatic resource cleanup.
- **🏗️ Structured State**: Provides `RState` for mutable values and `ComputedState` for derived data
  with automatic dependency tracking.
- **🔄 Compose-like DX**: Use `rememberState` to persist reactive state across widget
  rebuilds, offering a developer experience similar to Jetpack Compose.
- **🛠️ Bridge Utilities**: Easily convert legacy `ValueNotifier` or `ChangeNotifier` into modern
  reactive sources.

---

## 📦 Getting Started

### Installation

Add the dependency to your `pubspec.yaml`:

```yaml
dependencies:
  an_state: ^2.0.0
```

### Mandatory Lifecycle Setup

Initialize the lifecycle system at the root of your application:

```dart
import 'package:anlifecycle/anlifecycle.dart';

void main() {
  runApp(
    LifecycleApp( // 1. Wrap with LifecycleApp
      child: MaterialApp(
        // 2. Add the navigator observer
        navigatorObservers: [LifecycleNavigatorObserver.hookMode()],
        home: const HomePage(),
      ),
    ),
  );
}
```

---

## 📖 Usage Guide

### 1. Local Widget State

For UI-only state (like a toggle or a counter), use `rememberState` with `.asStateMutableOf` to avoid boilerplate `StatefulWidget`s.

```dart
@override
Widget build(BuildContext context) {
  // Persists across rebuilds, disposed when the widget is removed from the tree
  // Requires Lifecycle context
  final isExpanded = context.rememberState(false.asStateMutableOf);

  return Column(
    children: [
      Text("Details are ${isExpanded.value ? 'Visible' : 'Hidden'}"),
      ElevatedButton(
        onPressed: () => isExpanded.value = !isExpanded.value,
        child: const Text("Toggle"),
      ),
    ],
  );
}
```

### 2. In ViewModels (Business Logic)

Define your states using `state(...)` and `.asStateOf` / `.asStateMutableOf` extensions. These states will be automatically disposed
of when the ViewModel is cleared.

```dart
class UserViewModel extends ViewModel {
  // Use .asStateMutableOf extension to initialize mutable state
  late final username = state("Guest".asStateMutableOf);

  // Computed state depends on username (using .asStateOf or stateOf)
  late final greeting = state(stateOf(() => "Hello, ${username.value}!"));

  void updateName(String newName) {
    username.value = newName; // UI updates automatically
  }
}
```

### 3. In Widgets (UI Layer)

Access ViewModels and observe states with minimal boilerplate.

```dart
@override
Widget build(BuildContext context) {
  // Fetch ViewModel via extension (requires Lifecycle context)
  final vm = context.viewModels<UserViewModel>(factory: UserViewModel.new);

  // Use listenReactiveState to subscribe to a single state and get its value
  final name = context.listenReactiveState(vm.username);
  final message = context.listenReactiveState(vm.greeting);

  // Or use listenReactiveStates to observe multiple reactive states at once.
  context.listenReactiveStates(() {
    print("Active User: ${vm.username.value}");
  });

  return Column(
    children: [
      Text("User: $name, Message: $message"),
      TextField(onChanged: vm.updateName),
    ],
  );
}
```

---

## 💡 Advanced Code Examples

### Example A: Refreshable State & AsyncData Handling

Manage asynchronous data loading, loading indicators, error handling, and manual refreshes effortlessly using `RefreshableState` and `AsyncDataStateExt`.

```dart
class ProfileViewModel extends ViewModel {
  // Define a refreshable state with auto-loading enabled
  late final profileState = state(stateRefreshableOf((c) async {
    return await fetchUserProfile(c); // Returns Future<User>
  }, autoLoad: true));

  void refresh() {
    profileState.refreshData(); // Clears cache to loading and reloads
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.viewModels<ProfileViewModel>(factory: ProfileViewModel.new);
    final state = context.listenReactiveState(vm.profileState);

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.isError) {
      return Center(
        child: Column(
          children: [
            Text("Error: ${state.error}"),
            ElevatedButton(onPressed: vm.refresh, child: const Text("Retry")),
          ],
        ),
      );
    }

    final user = state.data; // Safe access to T when hasData is true
    return Scaffold(
      appBar: AppBar(title: Text(user.name)),
      body: Center(child: Text("Welcome back, ${user.email}!")),
    );
  }
}
```

### Example B: Lifecycle Side-Effects (`useEffect`)

React to reactive state changes inside a ViewModel by registering lifecycle-aware side-effects using `useEffect`.

```dart
class AnalyticsViewModel extends ViewModel {
  late final searchQuery = state("".asStateMutableOf);

  @override
  void onCreated() {
    super.onCreated();
    // Automatically runs when searchQuery.value changes.
    // Cleanly cancelled when the ViewModel is cleared.
    useEffect(() {
      final query = searchQuery.value;
      if (query.isNotEmpty) {
        print("Triggering analytics search for: $query");
      }
    });
  }
}
```

### Example C: Bridging Legacy `ValueNotifier`

Easily integrate traditional controllers or `ValueNotifier` into the reactive state graph using `.asStateOf`.

```dart
class CounterControllerViewModel extends ViewModel {
  final legacyNotifier = ValueNotifier<int>(0);

  // Bridge ValueNotifier directly into an RStateOf<ComputedState<int>>
  late final counterState = state(legacyNotifier.asStateOf);

  void increment() {
    legacyNotifier.value++;
  }
}
```

---

## 🛠️ Advanced Tools

### Initializers & Extension Getters

- `.asStateOf`: Extension getter on `Object`, `List`, `Set`, `Map`, and `ValueNotifier` to convert values into `RStateOf<ComputedState<T>>` (e.g. `"Guest".asStateOf`, `[1, 2].asStateOf`). Preferred for read-only / computed states.
- `.asStateMutableOf`: Extension getter on `Object`, `List`, `Set`, `Map`, and `ValueNotifier` to convert values into `RStateOf<RState<T>>` (e.g. `0.asStateMutableOf`, `"Guest".asStateMutableOf`). Preferred for mutable states.
- `nullAsStateOf<T>()`: Helper initializer for creating a `null` value computed state `RStateOf<ComputedState<T?>>`.
- `nullAsStateMutableOf<T>()`: Helper initializer for creating a `null` value mutable state `RStateOf<RState<T?>>`.
- `.asStateComputation`: Extension getter to convert values directly into `RStateComputer<T>` (`T Function()`).
- `.asNullableStateComputation`: Extension getter for nullable value initializers into `RStateComputer<T?>`.

### Bridge Tools

- `stateOfValueNotifier(notifier)` (or `notifier.asStateOf`): Converts a `ValueNotifier` into a reactive state source.
- `stateOfChangeNotifier(changeNotifier: notifier, computer: (cn) => cn.value)`: Converts any `ChangeNotifier` into a reactive state source.
- `stateOfAsync(...)`: Converts a `Future` or `Stream` into a reactive computer.
- `stateOfAsyncData(...)`: Converts a `Future` or `Stream` into a reactive `AsyncData<T>` computer.

### AsyncDataStateExt Extensions

Convenient extensions on `RState<AsyncData<T>>`:

- **State Checkers**: `isLoading`, `isError`, `isData`, `hasData`, `data`, `dataOrNull`, `error`, `stackTrace`.
- **State Mutators**: `toLoading()`, `toData(T data)`, `toError(Object error, [StackTrace? st])`, `toDataLoading()`, `toDataLoadingRaw(T data)`, `toDataError(Object error, [StackTrace? st])`, `toDataErrorRaw(T data, Object error, [StackTrace? st])`.

### Refreshable & Paginated States

- **`RefreshableState<T>`**: Manages refreshable async data with `refreshData()`, `reloadData()`, and `autoLoad`.
- **`RefreshablePagerState<T, K, Pager>`**: Manages paginated data with `loadNextPage()`, `refreshData()`, and `reloadData()`.
- **Usage**: Use `state(stateRefreshableOf(...))` in ViewModels and `rememberState(stateRefreshableOf(...))` in Widgets.

---

## 📚 Ecosystem & Underlying Packages

`an_state` combines the strengths of several core libraries:
- **[anlifecycle](https://pub.dev/packages/anlifecycle)**
- **[an_viewmodel](https://pub.dev/packages/an_viewmodel)**
- **[remember](https://pub.dev/packages/remember)**
- **[an_reactive_state](https://pub.dev/packages/an_reactive_state)**

---

## 📋 Core API Reference

| Method                           | Source         | Description                                                                                                                            |
|:---------------------------------|:---------------|:---------------------------------------------------------------------------------------------------------------------------------------|
| `asStateOf` / `asStateMutableOf` | `Extension`    | Extension getters on values (`"Guest".asStateOf`, `0.asStateMutableOf`) to create `RStateOf`. Preferred.                              |
| `nullAsStateOf` / `nullAsStateMutableOf` | `Function` | Helper initializers for creating `null`-valued `RStateOf`.                                                                             |
| `stateOf(computer)`              | `Function`     | Top-level factory function creating a read-only `ComputedState` (`RStateOf<ComputedState<T>>`).                                         |
| `stateMutableOf(value)`          | `Function`     | Top-level factory function creating a mutable `RState` (`RStateOf<RState<T>>`).                                                         |
| `state(stateOf)`                 | `ViewModel`    | Instantiates and binds an `RStateOf<S>` within the ViewModel's lifecycle.                                                             |
| `useEffect(action)`              | `ViewModel`    | Registers a lifecycle-aware reactive side-effect in the ViewModel.                                                                    |
| `rememberState(stateOf)`         | `BuildContext` | Remembers and binds a reactive state in the widget tree.                                                                               |
| `listenReactiveState(state)`     | `BuildContext` | Watches a single state and returns its value (triggers rebuild). Alias: `listenRawState`.                                              |
| `listenReactiveStates(computer)` | `BuildContext` | Watches multiple states accessed inside the callback (triggers rebuild).                                                               |
| `AsyncDataStateExt`              | `Extension`    | Convenience methods on `RState<AsyncData<T>>` for checking and mutating async states.                                                  |
| `RefreshableState`               | `Class`        | Reactive state class for refreshable async data with `refreshData()`, `reloadData()`, and `autoLoad`.                                   |
| `RefreshablePagerState`          | `Class`        | Reactive state class for paginated refreshable data.                                                                                   |
| `stateRefreshableOf(reloader)`   | `Function`     | Top-level factory function creating a `RefreshableState` (`RStateOf<RefreshableState<T>>`).                                             |
| `stateRefreshablePagerOf(loader)`| `Function`     | Top-level factory function creating a `RefreshablePagerState` (`RStateOf<RefreshablePagerState<T, K, P>>`).                            |
---
