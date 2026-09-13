# an_state

`an_state` is a powerful, lightweight reactive state management library for Flutter. It seamlessly
integrates the high-performance reactive engine
of [an_reactive_state](https://pub.dev/packages/an_reactive_state), the robust lifecycle management
of [an_viewmodel](https://pub.dev/packages/an_viewmodel), and the elegant state persistence
of [remember](https://pub.dev/packages/remember).

> [!IMPORTANT]
> `an_state` **strongly depends** on [anlifecycle](https://pub.dev/packages/anlifecycle). All core
> features, including `rememberState`, `rememberMutableState`, and `context.viewModels()`, require a
> valid `Lifecycle` context provided within the widget tree.

---

## 🚀 Key Features

- **🎯 Transparent Reactivity**: Based on `an_reactive_state`, UI updates automatically when state
  changes. No `notifyListeners()` or `setState()` required.
- **🧬 Lifecycle-Aware**: States are bound to the lifecycle of ViewModels or Widgets, ensuring zero
  memory leaks through automatic resource cleanup.
- **🏗️ Structured State**: Provides `RState` for mutable values and `ComputedState` for derived data
  with automatic dependency tracking.
- **🔄 Compose-like DX**: Use `rememberMutableState` to persist reactive state across widget
  rebuilds, offering a developer experience similar to Jetpack Compose.
- **🛠️ Bridge Utilities**: Easily convert legacy `ValueNotifier` or `ChangeNotifier` into modern
  reactive sources.

---

## 📦 Getting Started

### Installation

Add the dependency to your `pubspec.yaml`:

```yaml
dependencies:
  an_state: ^1.2.0
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

For UI-only state (like a toggle or a counter), use `remember` extensions to avoid boilerplate
`StatefulWidget`s.

```dart
@override
Widget build(BuildContext context) {
  // Persists across rebuilds, disposed when the widget is removed from the tree
  // Requires Lifecycle context
  final isExpanded = context.rememberMutableState(stateValueOf(false));

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

Define your states using `stateMutableOf` and `stateOf`. These states will be automatically disposed
of when the ViewModel is cleared.

```dart
class UserViewModel extends ViewModel {
  // Use stateValueOf to initialize mutable state
  late final username = stateMutableOf(stateValueOf("Guest"));

  // Computed state depends on username
  late final greeting = stateOf(() => "Hello, ${username.value}!");

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
  // Executes in a reactive scope (`effect`), automatically tracking accessed state dependencies.
  context.listenReactiveStates(() {
    print("Active User: ${vm.username.value}");
  });

  // Consuming AsyncData states with AsyncDataStateExt
  final userState = vm.userState; // RState<AsyncData<User>>
  context.listenReactiveState(userState);

  if (userState.isLoading) {
    return const CircularProgressIndicator();
  } else if (userState.isError) {
    return Text("Error: ${userState.error}");
  }

  return Column(
    children: [
      Text("User: ${userState.data.name}, Message: $message"),
      TextField(onChanged: vm.updateName),
    ],
  );
}
```

---

## 🛠️ Advanced Tools

### Initializers

- `stateValueOf(T value)`: Creates an initializer for a simple value.
- `stateListOf(List<T> list)`: Initializer for a reactive list.
- `stateMapOf(Map<K, V> map)`: Initializer for a reactive map.

### Bridge Tools

- `stateOfValueNotifier(valueNotifier: notifier)`: Converts a `ValueNotifier` into a reactive
  computer.
- `stateOfChangeNotifier(changeNotifier: notifier, computer: (cn) => cn.value)`: Converts any
  `ChangeNotifier` into a reactive computer.
- `stateOfAsync({required T initialValue, Future<T>? future, Stream<T>? stream, ...})`: Converts a
  `Future` or `Stream` into a reactive computer. Returns `initialValue` until an async value is
  received. Supports lazy factories `fFactory`/`fFactory2(cancellable)` and `sFactory`/
  `sFactory2(cancellable)`.
- `stateOfAsyncData<T>({T? initialValue, Future<T>? future, Stream<T>? stream, ...})`: Converts a
  `Future` or `Stream` into a reactive `AsyncData<T>` computer (starts as `AsyncData.loading()` or
  `AsyncData.value(initialValue)`). Supports lazy factories `fFactory`/`fFactory2(cancellable)` and
  `sFactory`/`sFactory2(cancellable)`.

### AsyncDataStateExt Extensions

Convenient extensions on `RState<AsyncData<T>>`:

- **State Checkers**: `isLoading`, `isError`, `isData`, `hasData`, `data`, `dataOrNull`, `error`,
  `stackTrace`.
- **State Mutators**:
    - `toLoading()`: Sets state to `AsyncData.loading()`.
    - `toData(T data)`: Sets state to `AsyncData.data(data)`.
    - `toError(Object error, [StackTrace? st])`: Sets state to `AsyncData.error(error, st)`.
    - `toDataLoading()`: Keeps existing data if `hasData` is true and sets
      `AsyncData.dataLoading(data)`, otherwise sets `AsyncData.loading()`.
    - `toDataLoadingRaw(T data)`: Sets state to `AsyncData.dataLoading(data)`.
    - `toDataError(Object error, [StackTrace? st])`: Keeps existing data if `hasData` is true and
      sets `AsyncData.dataError(data, error, st)`, otherwise sets `AsyncData.error(error, st)`.
    - `toDataErrorRaw(T data, Object error, [StackTrace? st])`: Sets state to
      `AsyncData.dataError(data, error, st)`.

### Optimization

- `expensiveComputation(Computer<T> computer)`: Ensures a heavy calculation or registration logic
  runs **only once** during the state's lifecycle.

---

## 📋 Core API Reference

| Method                           | Source         | Description                                                                                                                            |
|:---------------------------------|:---------------|:---------------------------------------------------------------------------------------------------------------------------------------|
| `stateMutableOf(computer)`       | `ViewModel`    | Creates a mutable `RState` bound to ViewModel.                                                                                         |
| `stateOf(computer)`              | `ViewModel`    | Creates a read-only `ComputedState`.                                                                                                   |
| `rememberMutableState(computer)` | `BuildContext` | Remembers a mutable state in the widget tree.                                                                                          |
| `rememberState(computer)`        | `BuildContext` | Remembers a computed state in the widget tree.                                                                                         |
| `listenReactiveState(state)`     | `BuildContext` | Watches a single state and returns its value (triggers rebuild). Alias: `listenRawState`.                                              |
| `listenReactiveStates(computer)` | `BuildContext` | Watches multiple states accessed inside the callback (triggers rebuild).                                                               |
| `stateOfAsync(...)`              | `Utility`      | Converts a Future or Stream into a reactive computer.                                                                                  |
| `stateOfAsyncData(...)`          | `Utility`      | Converts a Future or Stream into a reactive `AsyncData<T>` computer.                                                                   |
| `AsyncDataStateExt`              | `Extension`    | Convenience methods on `RState<AsyncData<T>>` for checking and mutating async states (`toData`, `toDataLoading`, `toDataError`, etc.). |

---

## 📄 License

This project is licensed under the Apache 2.0 License - see the [LICENSE](LICENSE) file for details.
