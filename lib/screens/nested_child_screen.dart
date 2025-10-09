import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../blocs/counter/counter_bloc.dart';
import '../blocs/counter/counter_event.dart';
import '../blocs/counter/counter_state.dart';
import '../blocs/user/user_bloc.dart';
import '../blocs/user/user_event.dart';
import '../blocs/user/user_state.dart';

/// Nested Child Screen - Deeply nested child route
/// This screen still inherits BLoCs from the parent route
class NestedChildScreen extends StatelessWidget {
  const NestedChildScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nested Child Screen'),
        backgroundColor: Colors.teal,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.account_tree, size: 80, color: Colors.teal),
              const SizedBox(height: 20),
              const Text(
                'Nested Child Screen',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.teal.shade300),
                ),
                child: const Text(
                  'Deeply nested route!\nStill has access to parent BLoCs 🎉',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 30),
              // Counter BLoC UI
              BlocBuilder<CounterBloc, CounterState>(
                builder: (context, state) {
                  return Card(
                    color: Colors.teal.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Text(
                            'Counter BLoC (from grandparent)',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Count: ${state.count}',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 10,
                            alignment: WrapAlignment.center,
                            children: [
                              ElevatedButton(
                                onPressed: () => context
                                    .read<CounterBloc>()
                                    .add(IncrementCounter()),
                                child: const Text('+5'),
                                onLongPress: () {
                                  for (int i = 0; i < 5; i++) {
                                    context.read<CounterBloc>().add(
                                      IncrementCounter(),
                                    );
                                  }
                                },
                              ),
                              ElevatedButton(
                                onPressed: () => context
                                    .read<CounterBloc>()
                                    .add(DecrementCounter()),
                                child: const Text('-5'),
                                onLongPress: () {
                                  for (int i = 0; i < 5; i++) {
                                    context.read<CounterBloc>().add(
                                      DecrementCounter(),
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              // User BLoC UI
              BlocBuilder<UserBloc, UserState>(
                builder: (context, state) {
                  return Card(
                    color: Colors.teal.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Text(
                            'User BLoC (from grandparent)',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Username: ${state.username}',
                            style: const TextStyle(fontSize: 16),
                          ),
                          Text(
                            'Email: ${state.email.isEmpty ? 'Not set' : state.email}',
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: () {
                              context.read<UserBloc>().add(
                                UpdateUsername('Nested User'),
                              );
                              context.read<UserBloc>().add(
                                UpdateEmail('nested@example.com'),
                              );
                            },
                            child: const Text('Update Both'),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 30),
              const Text(
                'Navigation Path: Home → Parent → Child1 → Nested',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () => context.pop(),
                    child: const Text('Back to Child 1'),
                  ),
                  ElevatedButton(
                    onPressed: () => context.go('/parent'),
                    child: const Text('Go to Parent'),
                  ),
                  ElevatedButton(
                    onPressed: () => context.go('/'),
                    child: const Text('Go to Home'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
