// Точка входа NOCTIS — Flutter-клиента.
// Configures Riverpod, edge-to-edge system UI, и локальные уведомления.
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/notifications/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
  ]);
  await SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.edgeToEdge,
  );

  // Инициализируем локальные уведомления заранее, чтобы канал был создан
  // до первой публикации.
  await NotificationService.init();

  runApp(const ProviderScope(child: NoctisApp()));
}
