# Video Selector Package# BLoC Inheritance POC with Go Router



A professional Flutter package for video selection with camera recording, gallery picking, and video trimming capabilities. Built with SOLID principles and clean architecture.This project demonstrates how to inherit BLoC instances from parent routes to child routes using `flutter_bloc` and `go_router` in Flutter.



## Features## 🎯 Key Concept



✅ **Camera Recording** - Professional camera with countdown, zoom, flash, and flip  The main idea is to use **ShellRoute** with **MultiBlocProvider** to provide BLoC instances to a parent route and all its child routes, without making the BLoC globally available in the entire app.

✅ **Gallery Selection** - Pick videos from device gallery with Android 13+ support  

✅ **Video Trimming** - Professional frame-based editor with drag controls  ## 🏗️ Architecture

✅ **Clean API** - Simple API returning `File` ready to use  

✅ **Configurable** - Extensive configuration options with presets  ### Route Structure

✅ **Platform Support** - Android & iOS with proper permissions```

/ (Home) - NO BLoC access

## Installation└── /parent (Parent) - BLoCs provided here via ShellRoute

    ├── /parent/child1 (Child 1) - Inherits BLoCs

Add this to your `pubspec.yaml`:    │   └── /parent/child1/nested (Nested) - Still inherits BLoCs

    └── /parent/child2 (Child 2) - Inherits BLoCs

```yaml```

dependencies:

  editable_video_picker:### BLoCs

    path: ../editable_video_picker  # or your package path- **CounterBloc**: Simple counter with increment, decrement, and reset

```- **UserBloc**: User data with username and email management



Or if using as a git dependency:## 🔑 Key Implementation Details



```yaml### 1. ShellRoute for BLoC Scoping

dependencies:The BLoCs are provided at the ShellRoute level, making them available only to routes within that shell:

  editable_video_picker:

    git:```dart

      url: https://github.com/your-org/editable_video_picker.gitShellRoute(

      ref: main  builder: (context, state, child) {

```    return MultiBlocProvider(

      providers: [

## Platform Setup        BlocProvider(create: (context) => CounterBloc()),

        BlocProvider(create: (context) => UserBloc()),

### Android      ],

      child: child,

Add to `android/app/src/main/AndroidManifest.xml`:    );

  },

```xml  routes: [

<uses-permission android:name="android.permission.CAMERA"/>    // Parent and child routes here

<uses-permission android:name="android.permission.RECORD_AUDIO"/>  ],

<uses-permission android:name="android.permission.READ_MEDIA_VIDEO" />)

<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />```

<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" 

    android:maxSdkVersion="32"/>### 2. Navigation Methods Demonstrated

<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" 

    android:maxSdkVersion="32"/>#### context.push() - Pushes on navigation stack

``````dart

context.push('/parent/child1')

### iOS```

- Preserves BLoC state

Add to `ios/Runner/Info.plist`:- Allows popping back to previous screen

- Used in: Home → Parent, Parent → Child1

```xml

<key>NSCameraUsageDescription</key>#### context.go() - Replaces current route

<string>We need camera access to record videos</string>```dart

<key>NSMicrophoneUsageDescription</key>context.go('/parent/child2')

<string>We need microphone access to record audio</string>```

<key>NSPhotoLibraryUsageDescription</key>- Still preserves BLoC state (within the same ShellRoute)

<string>We need access to select videos from your library</string>- Replaces navigation history

```- Used in: Parent → Child2



## Quick Start### 3. BLoC Scope Control

- **Home Screen**: NO access to BLoCs (outside ShellRoute)

### Basic Usage- **Parent Screen**: Has access to BLoCs (within ShellRoute)

- **Child Screens**: Inherit BLoCs from parent (within ShellRoute)

```dart- **Nested Children**: Still inherit BLoCs (within ShellRoute)

import 'package:editable_video_picker/video_selector.dart';

import 'dart:io';## 📱 Screens Overview



// Pick from camera### 1. Home Screen (`/`)

final File? video = await VideoPicker.pickVideo(- Entry point of the app

  context: context,- **No BLoC access** - demonstrates that BLoCs are not global

  source: VideoSource.camera,- Navigate to Parent to enter the BLoC scope

);

### 2. Parent Screen (`/parent`)

// Pick from gallery- **Provides BLoCs** via ShellRoute

final File? video = await VideoPicker.pickVideo(- Shows both Counter and User BLoC data

  context: context,- Can modify BLoC state

  source: VideoSource.gallery,- Navigate to Child1 (push) or Child2 (go)

);

```### 3. Child 1 Screen (`/parent/child1`)

- Accessed via `context.push()`

### Using Presets- **Inherits BLoCs** from parent

- Can modify the same BLoC instances

```dart- Shows that changes are reflected across screens

// Social media optimized (60s max, 3s min)

final video = await VideoPicker.pickVideo(### 4. Child 2 Screen (`/parent/child2`)

  context: context,- Accessed via `context.go()`

  source: VideoSource.camera,- **Inherits BLoCs** from parent

  config: VideoPickerConfig.social(),- Demonstrates that `go()` also preserves BLoC state

);- Can navigate between children



// Quick capture (30s max, simple UI)### 5. Nested Child Screen (`/parent/child1/nested`)

final video = await VideoPicker.pickVideo(- Deeply nested route

  context: context,- **Still inherits BLoCs** from the parent (grandparent)

  source: VideoSource.camera,- Demonstrates BLoC inheritance works at any nesting level

  config: VideoPickerConfig.quick(),

);## 🚀 Running the Project

```

1. **Install dependencies:**

### Custom Configuration   ```bash

   flutter pub get

```dart   ```

final video = await VideoPicker.pickVideo(

  context: context,2. **Run the app:**

  source: VideoSource.camera,   ```bash

  config: VideoPickerConfig(   flutter run

    editorConfig: EditorConfig(   ```

      maxDuration: Duration(seconds: 15),

      minDuration: Duration(seconds: 5),## 💡 Key Learnings

      enableHandleDrag: true,

      enableMiddleDrag: true,1. **ShellRoute is the key**: Use `ShellRoute` to scope BLoCs to specific route hierarchies

    ),2. **MultiBlocProvider**: Wrap the child in `MultiBlocProvider` to provide multiple BLoCs

    autoTrim: true,3. **BLoC Inheritance**: Child routes automatically inherit BLoCs from parent ShellRoute

    requireEditing: true,4. **Navigation Method Independence**: Both `push()` and `go()` preserve BLoC state within the same ShellRoute

  ),5. **Scoped, Not Global**: BLoCs are available only to routes within the ShellRoute, not the entire app

);

```## 📦 Dependencies



## Configuration Options```yaml

dependencies:

### VideoPickerConfig  flutter_bloc: ^8.1.6

  go_router: ^14.6.2

| Property | Type | Description | Default |```

|----------|------|-------------|---------|

| `editorConfig` | `EditorConfig` | Editor behavior configuration | `EditorConfig.defaultConfig()` |## 🎨 Features Demonstrated

| `cameraConfig` | `CameraRecorderConfig?` | Camera settings | `null` (uses defaults) |

| `autoTrim` | `bool` | Auto-trim after recording | `true` |✅ BLoC inheritance from parent to child routes  

| `requireEditing` | `bool` | Force editor screen | `true` |✅ Multiple levels of nesting with BLoC access  

✅ Both `context.push()` and `context.go()` navigation  

### EditorConfig✅ Scoped BLoC (not global)  

✅ Multiple BLoCs shared across routes  

| Property | Type | Description | Default |✅ State persistence across navigation  

|----------|------|-------------|---------|✅ Clean separation of BLoC scope  

| `maxDuration` | `Duration` | Maximum video duration | 30 seconds |

| `minDuration` | `Duration` | Minimum video duration | 1 second |## 📝 Notes

| `enableHandleDrag` | `bool` | Enable trim handle dragging | `true` |

| `enableMiddleDrag` | `bool` | Enable middle section dragging | `true` |- BLoCs are created when the ShellRoute is first accessed

- BLoCs are disposed when the ShellRoute is removed from navigation stack

### EditorConfig Presets- All child routes within the ShellRoute share the same BLoC instances

- This pattern is perfect for feature-scoped state management (e.g., authentication flow, checkout process, etc.)

```dart

// Default balanced settings

EditorConfig.defaultConfig()## Getting Started



// Social media (60s max, 3s min)This project is a starting point for a Flutter application.

EditorConfig.social()

A few resources to get you started if this is your first Flutter project:

// Quick editing (simple controls)

EditorConfig.quick()- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)

- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

// Precise editing (1s increments)

EditorConfig.precise(maxDuration: Duration(seconds: 30))For help getting started with Flutter development, view the

[online documentation](https://docs.flutter.dev/), which offers tutorials,

// View only (no editing)samples, guidance on mobile development, and a full API reference.

EditorConfig.viewOnly()
```

## API Reference

### VideoPicker

Main class for picking videos.

```dart
static Future<File?> pickVideo({
  required BuildContext context,
  required VideoSource source,
  VideoPickerConfig? config,
})
```

**Parameters:**
- `context` - BuildContext for navigation
- `source` - `VideoSource.camera` or `VideoSource.gallery`
- `config` - Optional configuration (uses defaults if not provided)

**Returns:** `File?` - Processed video file, or `null` if cancelled

### VideoSource

```dart
enum VideoSource {
  camera,   // Record from device camera
  gallery,  // Pick from device gallery
}
```

## Architecture

The package follows SOLID principles with a clean architecture:

```
lib/
├── video_selector.dart              # Main export file
└── video_selector/
    ├── video_picker.dart            # Main API (Facade)
    ├── models/                      # Data models
    ├── interfaces/                  # Abstract contracts
    ├── strategies/                  # Strategy implementations
    ├── services/                    # Business logic
    └── screens/                     # UI screens
```

## Example

Check the `example/` directory for complete working examples:

```bash
cd example
flutter run
```

## License

This package is private. Contact the repository owner for licensing information.
