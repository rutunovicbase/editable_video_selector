## BLoC Inheritance Flow Diagram

### Route Hierarchy and BLoC Scope

```
┌─────────────────────────────────────────────────────────────┐
│  MaterialApp.router                                         │
│                                                             │
│  ┌───────────────────────────────────────────────────────┐ │
│  │  / (Home Screen)                                      │ │
│  │  ❌ NO BLoC Access                                     │ │
│  │                                                        │ │
│  │  [Navigate to /parent]                                │ │
│  └───────────────────────────────────────────────────────┘ │
│                                                             │
│  ┌───────────────────────────────────────────────────────┐ │
│  │  ShellRoute (BLoC Provider Layer)                     │ │
│  │  ✅ MultiBlocProvider:                                 │ │
│  │     - CounterBloc                                      │ │
│  │     - UserBloc                                         │ │
│  │                                                        │ │
│  │  ┌─────────────────────────────────────────────────┐  │ │
│  │  │  /parent (Parent Screen)                        │  │ │
│  │  │  ✅ Has BLoC Access                              │  │ │
│  │  │                                                  │  │ │
│  │  │  ┌───────────────────────────────────────────┐  │  │ │
│  │  │  │  /parent/child1 (Child 1 Screen)         │  │  │ │
│  │  │  │  ✅ Inherits BLoC from parent             │  │  │ │
│  │  │  │  Navigation: context.push()              │  │  │ │
│  │  │  │                                           │  │  │ │
│  │  │  │  ┌─────────────────────────────────────┐ │  │  │ │
│  │  │  │  │  /parent/child1/nested              │ │  │  │ │
│  │  │  │  │  (Nested Child Screen)              │ │  │  │ │
│  │  │  │  │  ✅ Still inherits BLoC              │ │  │  │ │
│  │  │  │  └─────────────────────────────────────┘ │  │  │ │
│  │  │  └───────────────────────────────────────────┘  │  │ │
│  │  │                                                  │  │ │
│  │  │  ┌───────────────────────────────────────────┐  │  │ │
│  │  │  │  /parent/child2 (Child 2 Screen)         │  │  │ │
│  │  │  │  ✅ Inherits BLoC from parent             │  │  │ │
│  │  │  │  Navigation: context.go()                │  │  │ │
│  │  │  └───────────────────────────────────────────┘  │  │ │
│  │  └─────────────────────────────────────────────────┘  │ │
│  └───────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

### BLoC State Flow

```
User Action on Any Screen (Parent/Child1/Child2/Nested)
    ↓
context.read<CounterBloc>().add(IncrementCounter())
    ↓
BLoC processes event
    ↓
State emitted
    ↓
All BlocBuilder widgets across screens rebuild
    ↓
UI updated simultaneously on all screens
```

### Navigation Methods

#### context.push() - Stack Navigation
```
Home → Parent → Child1 → Nested
  ↑       ↑        ↑        ↑
  └───────┴────────┴────────┘
   Can pop back through stack
   BLoC state preserved
```

#### context.go() - Direct Navigation
```
Home → Parent → Child2
             ↓
         (replaces)
   BLoC state still preserved
   (within same ShellRoute)
```

### Key Concepts Illustrated

1. **BLoC Scoping**: BLoCs are provided at ShellRoute level, not globally
2. **Inheritance**: All routes within ShellRoute inherit the same BLoC instances
3. **State Sharing**: Changes in one screen are reflected in all other screens
4. **Navigation Independence**: Both push() and go() work with BLoC inheritance
5. **Lifecycle**: BLoCs are created when ShellRoute is accessed, disposed when removed

### Testing Scenarios

1. **Increment counter on Parent** → See it update on Child screens
2. **Update user on Child1** → See it update on Parent and Child2
3. **Navigate with push()** → BLoC state preserved
4. **Navigate with go()** → BLoC state still preserved
5. **Navigate to Home** → BLoC access lost (by design)
6. **Navigate back to Parent** → New BLoC instances created
