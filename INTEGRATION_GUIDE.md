# Integration Guide

Complete guide to integrating the Video Selector package into your Flutter project.

## Quick Integration (5 minutes)

### Step 1: Add Dependency

Add to your project's `pubspec.yaml`:

```yaml
dependencies:
  editable_video_picker:
    path: ../editable_video_picker  # Adjust path to where you place the module
```

Then run:
```bash
flutter pub get
```

### Step 2: Platform Setup

#### Android Setup

Add permissions to `android/app/src/main/AndroidManifest.xml` (inside `<manifest>` tag):

```xml
<!-- Camera and recording -->
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.RECORD_AUDIO"/>

<!-- Gallery access (Android 13+) -->
<uses-permission android:name="android.permission.READ_MEDIA_VIDEO" />
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />

<!-- Gallery access (Android 12 and below) -->
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" 
    android:maxSdkVersion="32"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" 
    android:maxSdkVersion="32"/>
```

Ensure minimum SDK in `android/app/build.gradle`:
```gradle
minSdkVersion 21
compileSdkVersion 33  // Or higher
```

#### iOS Setup

Add to `ios/Runner/Info.plist` (inside `<dict>` tag):

```xml
<key>NSCameraUsageDescription</key>
<string>We need camera access to record videos</string>

<key>NSMicrophoneUsageDescription</key>
<string>We need microphone access to record audio with videos</string>

<key>NSPhotoLibraryUsageDescription</key>
<string>We need access to select videos from your library</string>

<key>NSPhotoLibraryAddUsageDescription</key>
<string>We need access to save videos to your library</string>
```

Ensure minimum iOS version in `ios/Podfile`:
```ruby
platform :ios, '12.0'  # Or higher
```

### Step 3: Import and Use

```dart
import 'package:editable_video_picker/video_selector.dart';
import 'dart:io';

// In your widget:
final File? video = await VideoPicker.pickVideo(
  context: context,
  source: VideoSource.camera,  // or VideoSource.gallery
);

if (video != null) {
  // Video is ready to use!
  print('Video path: ${video.path}');
  // Upload, display, or process the video
}
```

## Complete Example

```dart
import 'package:flutter/material.dart';
import 'package:editable_video_picker/video_selector.dart';
import 'dart:io';

class MyVideoScreen extends StatefulWidget {
  @override
  State<MyVideoScreen> createState() => _MyVideoScreenState();
}

class _MyVideoScreenState extends State<MyVideoScreen> {
  File? _videoFile;
  bool _isLoading = false;

  Future<void> _recordVideo() async {
    setState(() => _isLoading = true);

    try {
      final video = await VideoPicker.pickVideo(
        context: context,
        source: VideoSource.camera,
        config: VideoPickerConfig.social(), // 60s max, optimized for social media
      );

      if (video != null && mounted) {
        setState(() {
          _videoFile = video;
          _isLoading = false;
        });
        
        // Now upload or use the video
        await _uploadVideo(video);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickFromGallery() async {
    setState(() => _isLoading = true);

    final video = await VideoPicker.pickVideo(
      context: context,
      source: VideoSource.gallery,
      config: VideoPickerConfig(
        editorConfig: EditorConfig(
          maxDuration: Duration(seconds: 30),
          minDuration: Duration(seconds: 3),
          enableHandleDrag: true,
          enableMiddleDrag: true,
        ),
      ),
    );

    if (video != null && mounted) {
      setState(() {
        _videoFile = video;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _uploadVideo(File video) async {
    // Your upload logic here
    print('Uploading ${video.path}...');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Video Recorder')),
      body: Center(
        child: _isLoading
            ? CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: _recordVideo,
                    icon: Icon(Icons.videocam),
                    label: Text('Record Video'),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _pickFromGallery,
                    icon: Icon(Icons.photo_library),
                    label: Text('Pick from Gallery'),
                  ),
                  if (_videoFile != null) ...[
                    SizedBox(height: 24),
                    Text('Video ready!'),
                    Text('${(_videoFile!.lengthSync() / 1024 / 1024).toStringAsFixed(2)} MB'),
                  ],
                ],
              ),
      ),
    );
  }
}
```

## Configuration Options

### Preset Configurations

```dart
// Default - balanced settings
VideoPicker.pickVideo(
  context: context,
  source: VideoSource.camera,
  config: VideoPickerConfig.defaultConfig(),
);

// Social Media - 60s max, 3s min
VideoPicker.pickVideo(
  context: context,
  source: VideoSource.camera,
  config: VideoPickerConfig.social(),
);

// Quick - 30s max, simple UI
VideoPicker.pickVideo(
  context: context,
  source: VideoSource.camera,
  config: VideoPickerConfig.quick(),
);
```

### Custom Configuration

```dart
VideoPicker.pickVideo(
  context: context,
  source: VideoSource.camera,
  config: VideoPickerConfig(
    editorConfig: EditorConfig(
      maxDuration: Duration(seconds: 15),  // Max 15 seconds
      minDuration: Duration(seconds: 5),   // Min 5 seconds
      enableHandleDrag: true,              // Allow dragging trim handles
      enableMiddleDrag: true,              // Allow dragging middle section
    ),
    autoTrim: true,                        // Auto-trim video
    requireEditing: true,                  // Show editor screen
  ),
);
```

### Editor Config Presets

```dart
// Precise editing with 1-second increments
EditorConfig.precise(
  maxDuration: Duration(seconds: 30),
  minDuration: Duration(seconds: 5),
)

// View only (no editing controls)
EditorConfig.viewOnly()

// Social media optimized
EditorConfig.social()
```

## Troubleshooting

### Common Issues

**Gallery not working on Android 13+**
- Ensure you have `READ_MEDIA_VIDEO` permission
- Set `compileSdkVersion` to 33 or higher

**Camera permission denied**
- Check permissions in AndroidManifest.xml and Info.plist
- Package automatically requests permissions at runtime

**Video compression fails**
- Test on physical device (emulators may have issues)
- Large videos may take time to compress

**Import errors**
- Make sure path in pubspec.yaml is correct
- Run `flutter pub get` after adding dependency
- Import as: `package:editable_video_picker/video_selector.dart`

## Testing the Integration

1. **Run the example app:**
   ```bash
   cd editable_video_picker
   flutter run lib/main.dart
   ```

2. **Test camera recording:**
   - Tap "Record from Camera"
   - Record a short video
   - Edit and trim
   - Verify file is returned

3. **Test gallery selection:**
   - Tap "Pick from Gallery"
   - Select a video
   - Edit and trim
   - Verify file is returned

## Module Placement

Recommended project structure:

```
your_project/
├── packages/
│   └── editable_video_picker/          # Place the module here
│       ├── lib/
│       ├── pubspec.yaml
│       └── ...
├── lib/
│   └── main.dart
└── pubspec.yaml                 # Your main project
```

Then reference it:
```yaml
dependencies:
  editable_video_picker:
    path: packages/editable_video_picker
```

## Next Steps

1. ✅ Complete platform setup (Android & iOS permissions)
2. ✅ Test basic camera and gallery functionality
3. ✅ Customize configuration for your use case
4. ✅ Implement video upload/processing logic
5. ✅ Add error handling and user feedback
6. ✅ Test on physical devices (both Android & iOS)

## Support

- **Documentation:** See `README.md` for full API reference
- **Examples:** Check `lib/main.dart` and `example/` directory
- **Structure:** Review `STRUCTURE.md` for architecture details
- **Changes:** See `CHANGELOG.md` for version history

## Clean Module Checklist

✅ No external demo files in lib/  
✅ Clean package exports via `video_selector.dart`  
✅ SOLID architecture maintained  
✅ All permissions documented  
✅ Simple public API (`VideoPicker.pickVideo()`)  
✅ Examples moved to `example/` directory  
✅ Comprehensive documentation  
✅ Ready for integration as module  

---

**Module Version:** 1.0.0  
**Flutter:** ^3.9.0  
**Platforms:** Android (API 21+), iOS (12.0+)
