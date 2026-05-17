# NOCTIS — мобильный клиент

Flutter-клиент мессенджера NOCTIS (iOS + Android) в чёрно-белой эстетике с 60fps анимациями.

## Запуск локально

```bash
flutter pub get
flutter run
```

## Сборка релизного APK

```bash
flutter build apk --release
# результат: build/app/outputs/flutter-apk/app-release.apk
```

## Структура

```
lib/
├── main.dart
├── app.dart
├── core/
│   ├── theme/         # Theme_Engine, монохромная палитра
│   ├── animation/     # длительности, кривые, haptics
│   ├── network/       # HTTP/WebSocket клиенты
│   └── routing/       # go_router
├── features/
│   ├── auth/          # welcome, phone, OTP, profile
│   ├── chats/         # список чатов
│   ├── messages/      # экран чата
│   └── settings/
└── ui/widgets/        # переиспользуемые компоненты
```
