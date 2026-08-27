# an_state

`an_state` is a powerful, lightweight reactive state management library for Flutter. It seamlessly integrates the high-performance reactive engine of `an_reactive_state`, the robust lifecycle management of `an_viewmodel`, and the elegant state persistence of `remember`.

> [!IMPORTANT]
> `an_state` **strongly depends** on [anlifecycle](https://pub.dev/packages/anlifecycle). All core features, including `rememberState`, `rememberMutableState`, and `context.viewModels()`, require a valid `Lifecycle` context provided within the widget tree.

---

## 🚀 Key Features

- **🎯 Transparent Reactivity**: Based on `an_reactive_state`, UI updates automatically when state changes. No `notifyListeners()` or `setState()` required.
- **🧬 Lifecycle-Aware**: States are bound to the lifecycle of ViewModels or Widgets, ensuring zero memory leaks through automatic resource cleanup.
- **🏗️ Structured State**: Provides `RState` for mutable values and `ComputedState` for derived data with automatic dependency tracking.
- **🔄 Compose-like DX**: Use `rememberMutableState` to persist reactive state across widget rebuilds, offering a developer experience similar to Jetpack Compose.
- **🛠️ Bridge Utilities**: Easily convert legacy `ValueNotifier` or `ChangeNotifier` into modern reactive sources.

---

## 📦 Getting Started

### Installation

Add the dependency to your `pubspec.yaml`:

```yaml
dependencies:
  an_state: ^0.0.1
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

### 1. In ViewModels (Business Logic)

Define your states using `stateMutableOf` and `stateOf`. These states will be automatically disposed of when the ViewModel is cleared.

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

### 2. In Widgets (UI Layer)

Access ViewModels and observe states with minimal boilerplate.

```dart
@override
Widget build(BuildContext context) {
  // Fetch ViewModel via extension (requires Lifecycle context)
  final vm = context.viewModels<UserViewModel>(factory: UserViewModel.new);
  
  // Use listenRawState to subscribe to changes and get the current value
  final name = context.listenRawState(vm.username);
  final message = context.listenRawState(vm.greeting);

  return Column(
    children: [
      Text(message),
      TextField(onChanged: vm.updateName),
    ],
  );
}
```

### 3. Local Widget State

For UI-only state (like a toggle or a counter), use `remember` extensions to avoid boilerplate `StatefulWidget`s.

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

---

## 🛠️ Advanced Tools

### Initializers
- `stateValueOf(T value)`: Creates an initializer for a simple value.
- `stateListOf(List<T> list)`: Initializer for a reactive list.
- `stateMapOf(Map<K, V> map)`: Initializer for a reactive map.

### Bridge Tools
- `stateOfValueNotifier(ValueNotifier<T> notifier)`: Converts a `ValueNotifier` into a reactive computer.
- `stateOfChangeNotifier(...)`: Converts any `ChangeNotifier` into a reactive computer.

### Optimization
- `expensiveComputation(Computer<T> computer)`: Ensures a heavy calculation or registration logic runs **only once** during the state's lifecycle.

---

## 📋 Core API Reference

| Method | Source | Description |
| :--- | :--- | :--- |
| `stateMutableOf(init)` | `ViewModel` | Creates a mutable `RState` bound to ViewModel. |
| `stateOf(computer)` | `ViewModel` | Creates a read-only `ComputedState`. |
| `rememberMutableState(init)` | `BuildContext` | Remembers a mutable state in the widget tree. |
| `rememberState(computer)` | `BuildContext` | Remembers a computed state in the widget tree. |
| `listenRawState(state)` | `BuildContext` | Watches a state and returns its value (triggers rebuild). |

---

## 📄 License

This project is licensed under the Apache 2.0 License - see the [LICENSE](LICENSE) file for details.
