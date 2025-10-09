# Code Examples - BLoC Inheritance Patterns

## 🎯 Core Pattern: ShellRoute with BLoC

### The Essential Pattern

```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

final router = GoRouter(
  routes: [
    // Route WITHOUT BLoC access
    GoRoute(
      path: '/',
      builder: (context, state) => HomeScreen(),
    ),
    
    // ShellRoute provides BLoCs to all children
    ShellRoute(
      builder: (context, state, child) {
        return MultiBlocProvider(
          providers: [
            BlocProvider(create: (context) => CounterBloc()),
            BlocProvider(create: (context) => UserBloc()),
            // Add more BLoCs as needed
          ],
          child: child, // This child will be the matched route
        );
      },
      routes: [
        // Parent route - has BLoC access
        GoRoute(
          path: '/parent',
          builder: (context, state) => ParentScreen(),
          routes: [
            // Child routes - inherit BLoCs from parent
            GoRoute(
              path: 'child1',
              builder: (context, state) => Child1Screen(),
            ),
            GoRoute(
              path: 'child2',
              builder: (context, state) => Child2Screen(),
            ),
          ],
        ),
      ],
    ),
  ],
);
```

## 📝 BLoC Definition Pattern

### 1. Define Events

```dart
// counter_event.dart
abstract class CounterEvent {}

class IncrementCounter extends CounterEvent {}

class DecrementCounter extends CounterEvent {}

class ResetCounter extends CounterEvent {}
```

### 2. Define State

```dart
// counter_state.dart
class CounterState {
  final int count;

  const CounterState({required this.count});

  CounterState copyWith({int? count}) {
    return CounterState(count: count ?? this.count);
  }
}
```

### 3. Define BLoC

```dart
// counter_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';

class CounterBloc extends Bloc<CounterEvent, CounterState> {
  CounterBloc() : super(const CounterState(count: 0)) {
    on<IncrementCounter>((event, emit) {
      emit(state.copyWith(count: state.count + 1));
    });

    on<DecrementCounter>((event, emit) {
      emit(state.copyWith(count: state.count - 1));
    });

    on<ResetCounter>((event, emit) {
      emit(const CounterState(count: 0));
    });
  }
}
```

## 🖥️ Using BLoC in Screens

### Pattern 1: Reading BLoC State (BlocBuilder)

```dart
import 'package:flutter_bloc/flutter_bloc.dart';

class ParentScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<CounterBloc, CounterState>(
        builder: (context, state) {
          // Rebuilds when state changes
          return Text('Count: ${state.count}');
        },
      ),
    );
  }
}
```

### Pattern 2: Dispatching Events

```dart
import 'package:flutter_bloc/flutter_bloc.dart';

// In button onPressed:
ElevatedButton(
  onPressed: () {
    // Get BLoC from context and add event
    context.read<CounterBloc>().add(IncrementCounter());
  },
  child: Text('Increment'),
)
```

### Pattern 3: Reading Multiple BLoCs

```dart
class ParentScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Counter BLoC
          BlocBuilder<CounterBloc, CounterState>(
            builder: (context, counterState) {
              return Text('Count: ${counterState.count}');
            },
          ),
          
          // User BLoC
          BlocBuilder<UserBloc, UserState>(
            builder: (context, userState) {
              return Text('User: ${userState.username}');
            },
          ),
        ],
      ),
    );
  }
}
```

### Pattern 4: Modifying Multiple BLoCs

```dart
ElevatedButton(
  onPressed: () {
    // Modify CounterBloc
    context.read<CounterBloc>().add(IncrementCounter());
    
    // Modify UserBloc
    context.read<UserBloc>().add(UpdateUsername('New User'));
  },
  child: Text('Update Both'),
)
```

## 🧭 Navigation Patterns

### Pattern 1: context.push() - Stack Navigation

```dart
// Push a new route on stack
ElevatedButton(
  onPressed: () => context.push('/parent/child1'),
  child: Text('Push to Child 1'),
)

// Benefits:
// - Can use back button to pop
// - Maintains navigation stack
// - BLoC state preserved (if within ShellRoute)
```

### Pattern 2: context.go() - Direct Navigation

```dart
// Replace current route
ElevatedButton(
  onPressed: () => context.go('/parent/child2'),
  child: Text('Go to Child 2'),
)

// Benefits:
// - Direct navigation
// - Replaces history
// - BLoC state still preserved (if within ShellRoute)
```

### Pattern 3: context.pop() - Go Back

```dart
// Go back to previous route
ElevatedButton(
  onPressed: () => context.pop(),
  child: Text('Back'),
)

// Benefits:
// - Returns to previous screen
// - BLoC state preserved
```

## 🎨 Complete Screen Example

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class ChildScreen extends StatelessWidget {
  const ChildScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Child Screen'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Display BLoC state
            BlocBuilder<CounterBloc, CounterState>(
              builder: (context, state) {
                return Text(
                  'Count: ${state.count}',
                  style: TextStyle(fontSize: 32),
                );
              },
            ),
            
            SizedBox(height: 20),
            
            // Modify BLoC state
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    context.read<CounterBloc>().add(DecrementCounter());
                  },
                  child: Text('-'),
                ),
                SizedBox(width: 20),
                ElevatedButton(
                  onPressed: () {
                    context.read<CounterBloc>().add(IncrementCounter());
                  },
                  child: Text('+'),
                ),
              ],
            ),
            
            SizedBox(height: 20),
            
            // Navigation
            ElevatedButton(
              onPressed: () => context.go('/parent'),
              child: Text('Go to Parent'),
            ),
          ],
        ),
      ),
    );
  }
}
```

## 🔄 BLoC Lifecycle in ShellRoute

```dart
// BLoC is created when ShellRoute is first accessed
User navigates to /parent
    ↓
ShellRoute builder called
    ↓
MultiBlocProvider creates BLoCs
    ↓
CounterBloc() initialized with count: 0
UserBloc() initialized with username: 'Guest'
    ↓
BLoCs available to all child routes

// BLoC persists across child navigation
User navigates /parent → /parent/child1
    ↓
Same BLoC instances used (count unchanged)
    ↓
User navigates /parent/child1 → /parent/child2
    ↓
Same BLoC instances used (count unchanged)

// BLoC is disposed when leaving ShellRoute
User navigates from /parent to /
    ↓
ShellRoute unmounted
    ↓
BLoCs disposed
    ↓
User navigates back to /parent
    ↓
New BLoC instances created (count reset to 0)
```

## 💡 Advanced Patterns

### Pattern: Conditional BLoC Access

```dart
// Check if BLoC is available
try {
  final bloc = context.read<CounterBloc>();
  bloc.add(IncrementCounter());
} catch (e) {
  print('BLoC not available in this context');
}
```

### Pattern: BLoC Listener for Side Effects

```dart
BlocListener<CounterBloc, CounterState>(
  listener: (context, state) {
    if (state.count == 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Count reached 10!')),
      );
    }
  },
  child: YourWidget(),
)
```

### Pattern: BlocConsumer (Builder + Listener)

```dart
BlocConsumer<CounterBloc, CounterState>(
  listener: (context, state) {
    // Side effects
    if (state.count < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Count is negative!')),
      );
    }
  },
  builder: (context, state) {
    // UI
    return Text('Count: ${state.count}');
  },
)
```

## 🎯 Common Mistakes to Avoid

### ❌ Wrong: Providing BLoC globally

```dart
// Don't do this if you want scoped BLoCs
void main() {
  runApp(
    MultiBlocProvider(  // ❌ Makes BLoCs available everywhere
      providers: [
        BlocProvider(create: (_) => CounterBloc()),
      ],
      child: MyApp(),
    ),
  );
}
```

### ✅ Right: Using ShellRoute for scoping

```dart
// Do this for scoped BLoCs
ShellRoute(
  builder: (context, state, child) {
    return MultiBlocProvider(  // ✅ Scoped to this route and children
      providers: [
        BlocProvider(create: (_) => CounterBloc()),
      ],
      child: child,
    );
  },
  routes: [...],
)
```

### ❌ Wrong: Creating BLoC in widget

```dart
// Don't do this - creates new instance on every rebuild
BlocBuilder<CounterBloc, CounterState>(
  bloc: CounterBloc(),  // ❌ New instance every rebuild
  builder: (context, state) => Text('${state.count}'),
)
```

### ✅ Right: Using provided BLoC from context

```dart
// Do this - uses inherited BLoC
BlocBuilder<CounterBloc, CounterState>(
  builder: (context, state) => Text('${state.count}'),  // ✅ Uses inherited BLoC
)
```

## 🚀 Quick Reference

| Task | Code |
|------|------|
| **Read state** | `BlocBuilder<MyBloc, MyState>` |
| **Dispatch event** | `context.read<MyBloc>().add(MyEvent())` |
| **Navigate (push)** | `context.push('/path')` |
| **Navigate (go)** | `context.go('/path')` |
| **Navigate (back)** | `context.pop()` |
| **Provide BLoC** | `BlocProvider(create: (_) => MyBloc())` |
| **Multiple BLoCs** | `MultiBlocProvider(providers: [...])` |
| **Scope BLoCs** | Use `ShellRoute` with `MultiBlocProvider` |

Happy coding! 🎉
