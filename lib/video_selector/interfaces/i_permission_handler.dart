/// Interface for permission handling
abstract class IPermissionHandler {
  Future<bool> requestCameraPermission();
  Future<bool> requestMicrophonePermission();
  Future<bool> requestStoragePermission();
  Future<bool> requestAllVideoPermissions();
}
