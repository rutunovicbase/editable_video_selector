import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../blocs/counter/counter_bloc.dart';
import '../blocs/counter/counter_event.dart';
import '../blocs/counter/counter_state.dart';
import '../blocs/user/user_bloc.dart';
import '../blocs/user/user_event.dart';
import '../blocs/user/user_state.dart';

/// Child Screen 2 - Accessed via context.go()
/// This screen inherits BLoCs from parent
class Child2Screen extends StatelessWidget {
  const Child2Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Child 2 Screen (Go)'),
        backgroundColor: Colors.purple,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.favorite, size: 80, color: Colors.purple),
              const SizedBox(height: 20),
              const Text(
                'Child 2 Screen',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.purple.shade300),
                ),
                child: const Text(
                  'Accessed via context.go()\nStill inherits BLoCs from parent!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 30),
              // Counter BLoC UI
              BlocBuilder<CounterBloc, CounterState>(
                builder: (context, state) {
                  return Card(
                    color: Colors.purple.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Text(
                            'Shared Counter BLoC',
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton(
                                onPressed: () => context
                                    .read<CounterBloc>()
                                    .add(DecrementCounter()),
                                child: const Text('Decrement'),
                              ),
                              const SizedBox(width: 10),
                              ElevatedButton(
                                onPressed: () => context
                                    .read<CounterBloc>()
                                    .add(ResetCounter()),
                                child: const Text('Reset'),
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
                    color: Colors.purple.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Text(
                            'Shared User BLoC',
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
                            onPressed: () => context.read<UserBloc>().add(
                              UpdateEmail('child2@example.com'),
                            ),
                            child: const Text('Update Email'),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 30),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () => context.go('/parent'),
                    child: const Text('Back to Parent (Go)'),
                  ),
                  ElevatedButton(
                    onPressed: () => context.go('/parent/child1'),
                    child: const Text('Go to Child 1'),
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
