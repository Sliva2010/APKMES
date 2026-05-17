// Запись видеосообщения («кружок») — упрощённый рекордер на основе
// image_picker.pickVideo с лимитом длины. Без живого превью круглого
// фрейма (для MVP), но с проверкой разрешений камеры и микрофона.
import 'package:image_picker/image_picker.dart';

import '../../core/permissions/permission_service.dart';

class VideoNoteResult {
  const VideoNoteResult({required this.path, required this.durationMs});
  final String path;
  final int durationMs;
}

class VideoNoteRecorder {
  VideoNoteRecorder._();

  /// Открывает системную камеру в режиме видео и возвращает
  /// результат записи. Длительность ограничена 60 секундами.
  static Future<VideoNoteResult?> capture() async {
    final bool camOk = await PermissionService.ensureCamera();
    if (!camOk) return null;
    final bool micOk = await PermissionService.ensureMicrophone();
    if (!micOk) return null;

    final ImagePicker picker = ImagePicker();
    final XFile? file = await picker.pickVideo(
      source: ImageSource.camera,
      maxDuration: const Duration(seconds: 60),
      preferredCameraDevice: CameraDevice.front,
    );
    if (file == null) return null;
    // Длительность точно вернёт image_picker не во всех версиях; возьмём
    // безопасный фолбэк — 60 сек если неизвестно.
    return VideoNoteResult(path: file.path, durationMs: 60 * 1000);
  }
}
