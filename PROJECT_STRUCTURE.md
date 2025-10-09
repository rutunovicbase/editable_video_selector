# Project Structure

## 📁 File Organization

```
inherited_bloc/
├── lib/
│   ├── main.dart                          # App entry point with MaterialApp.router
│   │
│   ├── router/
│   │   └── app_router.dart               # GoRouter configuration with ShellRoute
│   │
│   ├── blocs/
│   │   ├── counter/
│   │   │   ├── counter_bloc.dart         # Counter BLoC implementation
│   │   │   ├── counter_event.dart        # Counter events (Increment, Decrement, Reset)
│   │   │   └── counter_state.dart        # Counter state (count)
│   │   │
│   │   └── user/
│   │       ├── user_bloc.dart            # User BLoC implementation
│   │       ├── user_event.dart           # User events (UpdateUsername, UpdateEmail, Clear)
│   │       └── user_state.dart           # User state (username, email)
│   │
│   └── screens/
│       ├── home_screen.dart              # Home screen (NO BLoC access)
│       ├── parent_screen.dart            # Parent screen (provides BLoCs)
│       ├── child1_screen.dart            # Child 1 (inherits via push)
│       ├── child2_screen.dart            # Child 2 (inherits via go)
│       └── nested_child_screen.dart      # Nested child (deep inheritance)
│
├── pubspec.yaml                           # Dependencies (flutter_bloc, go_router)
├── README.md                              # Main documentation
├── ARCHITECTURE.md                        # Architecture diagrams
└── QUICK_START.md                        # User guide

```

## 🔑 Key Files Explained

### 1. main.dart
- Entry point of the application
- Sets up `MaterialApp.router` with the router configuration
- No BLoC providers here (they're in the router)

### 2. router/app_router.dart
- **Most Important File** for this POC
- Configures GoRouter with routes
- Uses `ShellRoute` to provide BLoCs to parent and child routes
- Demonstrates BLoC scoping pattern

### 3. blocs/
#### counter/
- Simple counter BLoC for demonstration
- Events: Increment, Decrement, Reset
- State: Single integer count

#### user/
- User data BLoC for demonstration
- Events: UpdateUsername, UpdateEmail, ClearUser
- State: username and email strings

### 4. screens/

#### home_screen.dart
- Entry screen (blue theme)
- **Outside ShellRoute** - no BLoC access
- Demonstrates BLoC is not global

#### parent_screen.dart
- **BLoC provider level** (green theme)
- Shows both Counter and User BLoC data
- Can navigate to children with push() or go()

#### child1_screen.dart
- Accessed via `context.push()` (orange theme)
- Inherits BLoCs from parent
- Can push to nested child

#### child2_screen.dart
- Accessed via `context.go()` (purple theme)
- Inherits BLoCs from parent
- Demonstrates go() also preserves BLoC

#### nested_child_screen.dart
- Deeply nested route (teal theme)
- Still inherits BLoCs from grandparent
- Demonstrates inheritance at any depth

## 🎨 Color Coding

Each screen has a unique theme color for easy identification:
- 🔵 **Blue** - Home (no BLoC)
- 🟢 **Green** - Parent (provides BLoCs)
- 🟠 **Orange** - Child 1 (push navigation)
- 🟣 **Purple** - Child 2 (go navigation)
- 🔵 **Teal** - Nested Child (deep nesting)

## 📦 Dependencies

### Production
```yaml
flutter_bloc: ^8.1.6   # BLoC state management
go_router: ^14.6.2     # Declarative routing
```

### Dev
```yaml
flutter_lints: ^5.0.0  # Linting rules
```

## 🔄 Data Flow

```
User Interaction
    ↓
Screen Widget
    ↓
context.read<BLoC>().add(Event)
    ↓
BLoC (in ShellRoute)
    ↓
emit(NewState)
    ↓
BlocBuilder rebuilds
    ↓
All screens update simultaneously
```

## 🛣️ Routing Flow

```
GoRouter
    ↓
Route: / (Home) - Simple GoRoute
    ↓
Route: /parent - ShellRoute starts here
    ↓
    MultiBlocProvider wraps child
        ├── CounterBloc
        └── UserBloc
    ↓
    All child routes inherit BLoCs:
        ├── /parent
        ├── /parent/child1
        ├── /parent/child1/nested
        └── /parent/child2
```

## 🎯 Learning Path

1. **Start with**: `main.dart` - See how router is configured
2. **Then read**: `app_router.dart` - Understand ShellRoute pattern
3. **Explore BLoCs**: See how events and states are defined
4. **Study screens**: See how BLoCs are used in UI
5. **Run app**: Test the actual behavior

## 💡 Best Practices Demonstrated

✅ **Separation of Concerns**: BLoCs, UI, and routing are separate  
✅ **Scoped State**: BLoCs only where needed, not global  
✅ **Clean Architecture**: Clear folder structure  
✅ **Reusable Patterns**: ShellRoute pattern can be applied to any feature  
✅ **Type Safety**: Strongly typed events and states  
✅ **Navigation Patterns**: Both push() and go() demonstrated  

## 🚀 How to Extend

### Add a New BLoC
1. Create folder in `blocs/`
2. Add event, state, and bloc files
3. Add to `MultiBlocProvider` in `app_router.dart`

### Add a New Screen
1. Create screen file in `screens/`
2. Add route in `app_router.dart`
3. Use inherited BLoCs with `context.read<YourBloc>()`

### Add Another Feature Area
1. Create a new `ShellRoute` for the feature
2. Provide feature-specific BLoCs
3. Add child routes for that feature

This pattern scales well for large applications with multiple feature areas! 🎉
