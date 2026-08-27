import 'package:flutter/material.dart';
import 'package:an_state/an_state.dart';
import 'package:an_viewmodel/an_viewmodel.dart';
import 'package:anlifecycle/anlifecycle.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return LifecycleApp(
      child: MaterialApp(
        navigatorObservers: [LifecycleNavigatorObserver.hookMode()],
        home: const HomePage(),
      ),
    );
  }
}

class CounterViewModel extends ViewModel {
  late final count = stateMutableOf(() => 0);
  late final isEven = stateOf(() => count.value % 2 == 0);

  void increment() {
    count.value++;
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const HomePageContent();
  }
}

class HomePageContent extends StatelessWidget {
  const HomePageContent({super.key});

  @override
  Widget build(BuildContext context) {
    // Accessing the ViewModel via context.viewModels()
    // The factory is provided here; it will only be called if the ViewModel doesn't exist yet.
    final vm =
        context.viewModels<CounterViewModel>(factory: CounterViewModel.new);

    return Scaffold(
      appBar: AppBar(title: const Text('an_state Example')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
                'Count (from ViewModel): ${context.listenRawState(vm.count)}'),
            Text(
                'Is Even: ${context.listenRawState(vm.isEven)}'),
            const SizedBox(height: 20),
            const LocalCounter(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: vm.increment,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class LocalCounter extends StatelessWidget {
  const LocalCounter({super.key});

  @override
  Widget build(BuildContext context) {
    // Using rememberMutableState for local UI state
    final localCount = context.rememberMutableState(() => 0);

    return Column(
      children: [
        const Text('Local state (using remember):'),
        Text('${localCount.value}',
            style: Theme.of(context).textTheme.headlineMedium),
        ElevatedButton(
          onPressed: () => localCount.value++,
          child: const Text('Increment Local'),
        ),
      ],
    );
  }
}
