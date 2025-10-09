import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../blocs/counter/counter_bloc.dart';
import '../blocs/user/user_bloc.dart';
import '../screens/home_screen.dart';
import '../screens/parent_screen.dart';
import '../screens/child1_screen.dart';
import '../screens/child2_screen.dart';
import '../screens/nested_child_screen.dart';

final GoRouter router = GoRouter(
  initialLocation: '/',
  routes: [
    // Home route - NO BLoC access
    GoRoute(path: '/', builder: (context, state) => const HomeScreen()),

    // Parent route with ShellRoute to provide BLoCs to all children
    ShellRoute(
      builder: (context, state, child) {
        // This is where we provide BLoCs for the parent and all child routes
        return MultiBlocProvider(
          providers: [
            BlocProvider(create: (context) => CounterBloc()),
            BlocProvider(create: (context) => UserBloc()),
          ],
          child: child,
        );
      },
      routes: [
        // Parent route
        GoRoute(
          path: '/parent',
          builder: (context, state) => const ParentScreen(),
          routes: [
            // Child 1 route (accessed via push)
            GoRoute(
              path: 'child1',
              builder: (context, state) => const Child1Screen(),
              routes: [
                // Nested child route
                GoRoute(
                  path: 'nested',
                  builder: (context, state) => const NestedChildScreen(),
                ),
              ],
            ),
            // Child 2 route (accessed via go)
            GoRoute(
              path: 'child2',
              builder: (context, state) => const Child2Screen(),
            ),
          ],
        ),
      ],
    ),
  ],
);
