# an_state

`an_state` is a reactive state management library for Flutter. It combines the power of `an_reactive_state` with the lifecycle management of `an_viewmodel` and the in-widget persistence of `remember`, providing a concise, efficient, and automated solution for handling application state.

> [!IMPORTANT]
> `an_state` **strongly depends** on [anlifecycle](https://pub.dev/packages/anlifecycle). Core features like `rememberState`, `rememberMutableState`, and `context.viewModels()` strictly require a `Lifecycle` context provided in the widget tree.

## Features

- **Reactive State**: Built on top of `an_reactive_state`, supporting both `RState` (mutable state) and `ComputedState` (computed properties).
- **ViewModel Integration**: Provides `ViewModel` extensions to easily create reactive states bound to the ViewModel's lifecycle.
- **Widget Local State**: A `remember`-like mechanism (inspired by Compose) to persist reactive states directly within the Widget tree.
- **Auto Dependency Tracking**: No manual subscriptions required; state changes automatically trigger related computations and UI updates.
- **Lifecycle Safety**: Leverages `cancellable` and `anlifecycle` to ensure resources are automatically released.

## Getting Started

### Installation

Add `an_state` to your `pubspec.yaml`:

```yaml
dependencies:
  an_state: ^0.0.1
```

### Lifecycle Setup

You **must** wrap your application with `LifecycleApp` and configure `LifecycleNavigatorObserver` to provide the necessary lifecycle context for `remember` and `ViewModel` extensions:

```dart
void main() {
  runApp(
    LifecycleApp(
      child: MaterialApp(
        navigatorObservers: [LifecycleNavigatorObserver.hookMode()],
        home: const HomePage(),
      ),
    ),
  );
}
```

## Usage

### Usage in ViewModel

Use `stateOf` for computed properties or `stateMutableOf` for mutable states:

```dart
class MyViewModel extends ViewModel {
  // Mutable state
  late final count = stateMutableOf(stateValueOf(0));

  // Computed state, automatically updates when count changes
  late final doubleCount = stateOf(() => count.value * 2);

  void increment() {
    count.value++;
  }
}
```

Then access it in your Widget using `listenRawState` to enable reactivity:

```dart
@override
Widget build(BuildContext context) {
  // Access ViewModel (requires Lifecycle context)
  final vm = context.viewModels<MyViewModel>(factory: MyViewModel.new);
  
  // Observe reactive property
  final count = context.listenRawState(vm.count);
  
  return Text('Count: $count');
}
```

### Usage in Widget (Local State)

Use `BuildContext` extensions to "remember" state within the `build` method (similar to Jetpack Compose):

```dart
@override
Widget build(BuildContext context) {
  // Persist a reactive state within the Widget tree (requires Lifecycle context)
  final localCount = context.rememberMutableState(stateValueOf(0));

  return TextButton(
    onPressed: () => localCount.value++,
    child: Text('Local Count: ${localCount.value}'),
  );
}
```

## Core API

- **ViewModel Extensions**:
  - `stateOf`: Creates a read-only computed state.
  - `stateMutableOf`: Creates a read-write mutable state.
- **BuildContext Extensions**:
  - `listenRawState`: Listens to a `BaseState` (RState or ComputedState) and returns its current value.
  - `rememberState`: Remembers a computed state at the component level.
  - `rememberMutableState`: Remembers a mutable state at the component level.
- **Utility Functions**:
  - `stateOfValueNotifier`: Observes a `ValueNotifier`.
  - `stateOfChangeNotifier`: Observes a `ChangeNotifier`.
  - `expensiveComputation`: Ensures heavy logic is only executed once.

## License

[Apache 2.0 LICENSE](LICENSE)
