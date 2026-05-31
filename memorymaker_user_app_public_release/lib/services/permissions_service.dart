import 'package:permission_handler/permission_handler.dart';

class PermissionsService {
  static Future<bool> requestGallery() async {
    final photos = await Permission.photos.request();
    final storage = await Permission.storage.request();
    return photos.isGranted || photos.isLimited || storage.isGranted;
  }

  static Future<bool> requestCamera() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  static Future<bool> requestNotifications() async {
    final status = await Permission.notification.request();
    return status.isGranted || status.isLimited;
  }
}
