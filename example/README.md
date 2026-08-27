# an_state Example

This example demonstrates how to use the `an_state` package to manage both global (ViewModel-based) and local (Widget-based) reactive states in a Flutter application.

## Key Concepts Demonstrated

1.  **ViewModel Integration**: Using `stateMutableOf` and `stateOf` inside a `ViewModel` to manage business logic state.
2.  **Local State Persistence**: Using `context.rememberMutableState` to maintain reactive state directly within a `StatelessWidget`, similar to Jetpack Compose's `remember`.
3.  **Automatic UI Updates**: How the UI automatically refreshes when reactive states change without manual listeners or `setState`.

## How to Run

1.  Navigate to this directory: `cd example`
2.  Get dependencies: `flutter pub get`
3.  Run the app: `flutter run`
