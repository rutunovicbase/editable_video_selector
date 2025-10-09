# BLoC Inheritance POC with Go Router

This project demonstrates how to inherit BLoC instances from parent routes to child routes using `flutter_bloc` and `go_router` in Flutter.

## 🎯 Key Concept

The main idea is to use **ShellRoute** with **MultiBlocProvider** to provide BLoC instances to a parent route and all its child routes, without making the BLoC globally available in the entire app.

## 🏗️ Architecture

### Route Structure
```
/ (Home) - NO BLoC access
└── /parent (Parent) - BLoCs provided here via ShellRoute
    ├── /parent/child1 (Child 1) - Inherits BLoCs
    │   └── /parent/child1/nested (Nested) - Still inherits BLoCs
    └── /parent/child2 (Child 2) - Inherits BLoCs
```

### BLoCs
- **CounterBloc**: Simple counter with increment, decrement, and reset
- **UserBloc**: User data with username and email management

## 🔑 Key Implementation Details

### 1. ShellRoute for BLoC Scoping
The BLoCs are provided at the ShellRoute level, making them available only to routes within that shell:

```dart
ShellRoute(
  builder: (context, state, child) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => CounterBloc()),
        BlocProvider(create: (context) => UserBloc()),
      ],
      child: child,
    );
  },
  routes: [
    // Parent and child routes here
  ],
)
```

### 2. Navigation Methods Demonstrated

#### context.push() - Pushes on navigation stack
```dart
context.push('/parent/child1')
```
- Preserves BLoC state
- Allows popping back to previous screen
- Used in: Home → Parent, Parent → Child1

#### context.go() - Replaces current route
```dart
context.go('/parent/child2')
```
- Still preserves BLoC state (within the same ShellRoute)
- Replaces navigation history
- Used in: Parent → Child2

### 3. BLoC Scope Control
- **Home Screen**: NO access to BLoCs (outside ShellRoute)
- **Parent Screen**: Has access to BLoCs (within ShellRoute)
- **Child Screens**: Inherit BLoCs from parent (within ShellRoute)
- **Nested Children**: Still inherit BLoCs (within ShellRoute)

## 📱 Screens Overview

### 1. Home Screen (`/`)
- Entry point of the app
- **No BLoC access** - demonstrates that BLoCs are not global
- Navigate to Parent to enter the BLoC scope

### 2. Parent Screen (`/parent`)
- **Provides BLoCs** via ShellRoute
- Shows both Counter and User BLoC data
- Can modify BLoC state
- Navigate to Child1 (push) or Child2 (go)

### 3. Child 1 Screen (`/parent/child1`)
- Accessed via `context.push()`
- **Inherits BLoCs** from parent
- Can modify the same BLoC instances
- Shows that changes are reflected across screens

### 4. Child 2 Screen (`/parent/child2`)
- Accessed via `context.go()`
- **Inherits BLoCs** from parent
- Demonstrates that `go()` also preserves BLoC state
- Can navigate between children

### 5. Nested Child Screen (`/parent/child1/nested`)
- Deeply nested route
- **Still inherits BLoCs** from the parent (grandparent)
- Demonstrates BLoC inheritance works at any nesting level

## 🚀 Running the Project

1. **Install dependencies:**
   ```bash
   flutter pub get
   ```

2. **Run the app:**
   ```bash
   flutter run
   ```

## 💡 Key Learnings

1. **ShellRoute is the key**: Use `ShellRoute` to scope BLoCs to specific route hierarchies
2. **MultiBlocProvider**: Wrap the child in `MultiBlocProvider` to provide multiple BLoCs
3. **BLoC Inheritance**: Child routes automatically inherit BLoCs from parent ShellRoute
4. **Navigation Method Independence**: Both `push()` and `go()` preserve BLoC state within the same ShellRoute
5. **Scoped, Not Global**: BLoCs are available only to routes within the ShellRoute, not the entire app

## 📦 Dependencies

```yaml
dependencies:
  flutter_bloc: ^8.1.6
  go_router: ^14.6.2
```

## 🎨 Features Demonstrated

✅ BLoC inheritance from parent to child routes  
✅ Multiple levels of nesting with BLoC access  
✅ Both `context.push()` and `context.go()` navigation  
✅ Scoped BLoC (not global)  
✅ Multiple BLoCs shared across routes  
✅ State persistence across navigation  
✅ Clean separation of BLoC scope  

## 📝 Notes

- BLoCs are created when the ShellRoute is first accessed
- BLoCs are disposed when the ShellRoute is removed from navigation stack
- All child routes within the ShellRoute share the same BLoC instances
- This pattern is perfect for feature-scoped state management (e.g., authentication flow, checkout process, etc.)


## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
