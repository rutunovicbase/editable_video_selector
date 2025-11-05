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
    // For Android 13+ (API 33+), use specific media permissions
    // For iOS, use photos permission
    if (Platform.isAndroid) {
      // Android 13+ uses granular media permissions
      final status = await Permission.videos.request();
      if (status.isGranted) return true;

      // Fallback to photos for older Android versions
      final photoStatus = await Permission.photos.request();
      if (photoStatus.isGranted) return true;

      // Check if permanently denied and guide user
      if (status.isPermanentlyDenied || photoStatus.isPermanentlyDenied) {
        await openAppSettings();
        return false;
      }

      return false;
    } else {
      // iOS uses photos permission
      final status = await Permission.photos.request();

      if (status.isGranted || status.isLimited) {
        return true;
      }

      if (status.isPermanentlyDenied) {
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
