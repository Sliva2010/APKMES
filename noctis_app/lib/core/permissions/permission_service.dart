// Тонкая обёртка над permission_handler.
// Все методы возвращают true, если разрешение в итоге получено.
import 'dart:io';

import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  PermissionService._();

  /// Камера — для фото/видео и кружков.
  static Future<bool> ensureCamera() async {
    final PermissionStatus s = await Permission.camera.request();
    return s.isGranted || s.isLimited;
  }

  /// Микрофон — для голосовых, видеосообщений и звонков.
  static Future<bool> ensureMicrophone() async {
    final PermissionStatus s = await Permission.microphone.request();
    return s.isGranted || s.isLimited;
  }

  /// Доступ к фото/галерее. На Android 13+ это READ_MEDIA_IMAGES.
  static Future<bool> ensurePhotos() async {
    if (Platform.isAndroid) {
      final PermissionStatus images = await Permission.photos.request();
      if (images.isGranted || images.isLimited) return true;
      // Фолбэк для старых Android (< 13).
      final PermissionStatus storage = await Permission.storage.request();
      return storage.isGranted || storage.isLimited;
    }
    final PermissionStatus s = await Permission.photos.request();
    return s.isGranted || s.isLimited;
  }

  /// Видео из галереи.
  static Future<bool> ensureVideos() async {
    if (Platform.isAndroid) {
      final PermissionStatus s = await Permission.videos.request();
      if (s.isGranted || s.isLimited) return true;
      final PermissionStatus storage = await Permission.storage.request();
      return storage.isGranted || storage.isLimited;
    }
    return ensurePhotos();
  }

  /// Уведомления.
  static Future<bool> ensureNotifications() async {
    final PermissionStatus s = await Permission.notification.request();
    return s.isGranted;
  }

  /// Текущий статус (без запроса).
  static Future<bool> hasNotifications() async {
    final PermissionStatus s = await Permission.notification.status;
    return s.isGranted;
  }

  static Future<bool> hasMicrophone() async {
    final PermissionStatus s = await Permission.microphone.status;
    return s.isGranted;
  }

  static Future<bool> hasCamera() async {
    final PermissionStatus s = await Permission.camera.status;
    return s.isGranted;
  }
}
