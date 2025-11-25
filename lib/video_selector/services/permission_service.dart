import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import '../interfaces/i_permission_handler.dart';

/// Concrete implementation of permission handling
class PermissionService implements IPermissionHandler {
  @override
  Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  @override
  Future<bool> requestMicrophonePermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  @override
  Future<bool> requestStoragePermission() async {
    if (Platform.isIOS) {
      final status = await Permission.photos.request();

      if (status.isGranted || status.isLimited) {
        return true;
      }

      if (status.isPermanentlyDenied) {
        await openAppSettings();
      }

      return false;
    } else {
      // Android path (same as before)
      final videos = await Permission.videos.request();
      final photos = await Permission.photos.request();
      final storage = await Permission.storage.request();

      if (videos.isGranted || photos.isGranted || storage.isGranted) {
        return true;
      }

      if (videos.isPermanentlyDenied ||
          photos.isPermanentlyDenied ||
          storage.isPermanentlyDenied) {
        await openAppSettings();
      }

      return false;
    }
  }


  @override
  Future<bool> requestAllVideoPermissions() async {
    final cameraGranted = await requestCameraPermission();
    final micGranted = await requestMicrophonePermission();
    final storageGranted = await requestStoragePermission();

    return cameraGranted && micGranted && storageGranted;
  }
}
