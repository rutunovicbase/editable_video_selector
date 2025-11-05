# Package Structure

This document describes the clean module structure for the Video Selector package.

## Directory Structure

```
editable_video_picker/
├── lib/
│   ├── video_selector.dart                    # Main package export file
│   ├── main.dart                               # Simple example app
│   └── video_selector/                        # Package implementation
│       ├── video_picker.dart                   # Main API (Facade pattern)
│       ├── video_selector.dart                 # Internal exports
│       ├── models/                             # Data models
│       │   ├── editor_config.dart              # Editor configuration
│       │   ├── trim_data.dart                  # Trim range data
│       │   └── video_selection_source.dart     # Source enum (camera/gallery)
│       ├── interfaces/                         # Abstract contracts (SOLID)
│       │   ├── i_permission_handler.dart
│       │   ├── i_video_selection_strategy.dart
│       │   └── i_video_trimmer.dart
│       ├── strategies/                         # Strategy pattern implementations
│       │   ├── camera_video_selection_strategy.dart
│       │   └── gallery_video_selection_strategy.dart
│       ├── services/                           # Business logic services
│       │   ├── permission_service.dart
│       │   ├── video_selection_service.dart
│       │   └── video_trimmer_service.dart
│       └── screens/                            # UI screens
│           ├── camera_recorder_screen.dart
│           └── video_editor_screen.dart
├── example/                                    # Example apps
│   ├── main.dart                               # Simple example
│   ├── package_demo.dart                       # Full-featured demo
│   └── main_old_backup.dart                    # Legacy backup
├── android/                                    # Android platform
├── ios/                                        # iOS platform
├── test/                                       # Unit tests
├── pubspec.yaml                                # Package configuration
├── README.md                                   # Main documentation
└── CHANGELOG.md                                # Version history
```

## Clean Architecture

### Layer Separation

1. **API Layer** (`video_picker.dart`)
   - Simple, clean public API
   - Returns `File` directly
   - Hides internal complexity

2. **Service Layer** (`services/`)
   - Business logic
   - Platform-specific handling
   - Video processing

3. **Strategy Layer** (`strategies/`)
   - Camera vs Gallery implementations
   - Dependency Injection
   - Follows Strategy pattern

4. **Interface Layer** (`interfaces/`)
   - Abstract contracts
   - Enables testing and mocking
   - Follows Dependency Inversion Principle

5. **UI Layer** (`screens/`)
   - Camera recorder
   - Video editor
   - Self-contained widgets

## Usage as Module

### Add to Your Project

**Option 1: Local Path**
```yaml
dependencies:
  editable_video_picker:
    path: ../path/to/editable_video_picker
```

**Option 2: Git Repository**
```yaml
dependencies:
  editable_video_picker:
    git:
      url: https://github.com/your-org/editable_video_picker.git
      ref: main
```

### Import in Your Code

```dart
import 'package:editable_video_picker/video_selector.dart';
```

### Use the API

```dart
final File? video = await VideoPicker.pickVideo(
  context: context,
  source: VideoSource.camera,
  config: VideoPickerConfig.social(),
);
```

## What's Exported

The package exports only what's needed:

- `VideoPicker` - Main API class
- `VideoPickerConfig` - Configuration class
- `VideoSource` - Enum (camera/gallery)
- `EditorConfig` - Editor settings
- `TrimData` - Trim range data
- `PermissionService` - For advanced permission handling
- `VideoTrimmerService` - For advanced trimming

Internal implementation details are hidden.

## Key Features for Module Use

✅ **Clean API** - Simple `pickVideo()` method  
✅ **No Setup Required** - Works out of the box  
✅ **Configurable** - Multiple presets + custom configs  
✅ **Platform Ready** - Android & iOS permissions documented  
✅ **Type Safe** - Returns `File`, no custom models to learn  
✅ **Well Documented** - README, examples, inline docs  
✅ **SOLID Design** - Easy to extend or customize  
✅ **No External Dependencies** - Only Flutter plugins, no state management

## Running Examples

```bash
# Simple example
flutter run lib/main.dart

# Full-featured demo
flutter run example/package_demo.dart
```

## Testing the Module

```bash
# Run all tests
flutter test

# Analyze code
flutter analyze

# Check outdated dependencies
flutter pub outdated
```

## Integration Checklist

- [ ] Add dependency to your `pubspec.yaml`
- [ ] Copy platform permissions to your AndroidManifest.xml
- [ ] Copy platform permissions to your Info.plist
- [ ] Import `package:editable_video_picker/video_selector.dart`
- [ ] Call `VideoPicker.pickVideo()`
- [ ] Handle returned `File` or `null`

## Support

- Check `README.md` for detailed API documentation
- See `example/` directory for working code
- Review `CHANGELOG.md` for version updates
