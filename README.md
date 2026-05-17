# NOCTIS

**NOCTIS** — премиальный кроссплатформенный мессенджер в строгой чёрно-белой эстетике. Минимализм, скорость и приватность: личные чаты в реальном времени, голосовые и видеозвонки, исчезающие сообщения, секретные чаты со сквозным шифрованием (X3DH + Double Ratchet) и более 100 продуманных функций.

> Демо-режим текущей версии: офлайн UX-демонстрация на Flutter. Бэкенд (Go + PostgreSQL + Redis + MinIO) и сетевой обмен подключаются согласно плану `tasks.md`.

## Технологический стек

- **Клиент:** Flutter 3.x / Dart 3.x — единая кодовая база iOS и Android, Riverpod 2.x.
- **Бэкенд:** Go 1.22, Fiber, WebSocket, PostgreSQL 15, Redis 7, MinIO, coturn.
- **Инфраструктура:** Ubuntu 22.04 LTS, Docker Compose, Nginx (TLS 1.2/1.3), Let's Encrypt.
- **CI/CD:** GitHub Actions — сборка релизного APK при пуше в `main`, публикация в GitHub Releases.

## Структура монорепо

```
.
├── noctis_app/        # Flutter-клиент (iOS + Android)
├── noctis_backend/    # Go-бэкенд (Fiber + WebSocket) — будет добавлен
├── api/               # OpenAPI 3.1, JSON Schema WebSocket-протокола
├── deploy/            # Docker Compose, Nginx, provision-скрипты
├── docs/              # Дополнительная проектная документация
└── .github/workflows/ # GitHub Actions: CI, релизы APK
```

## Спецификация

Полная спецификация продукта ведётся как Kiro-spec в каталоге `.kiro/specs/monochrome-messenger/`:

- [Requirements](.kiro/specs/monochrome-messenger/requirements.md) — функциональные и нефункциональные требования (EARS / INCOSE).
- [Design](.kiro/specs/monochrome-messenger/design.md) — архитектура, компоненты, контракты, модели данных, 14 свойств корректности.
- [Tasks](.kiro/specs/monochrome-messenger/tasks.md) — план поэтапной реализации.

## Получить APK

После пуша в `main` GitHub Actions автоматически:

1. Соберёт релизный APK (`flutter build apk --release`).
2. Опубликует его в GitHub Releases с тегом `vYYYYMMDD-<sha7>`.
3. Файл `noctis-release.apk` будет доступен для прямой установки на Android.

Скачать вручную: вкладка **Actions → Build NOCTIS APK → Artifacts → noctis-release-apk**.

## Запуск локально (Flutter)

```bash
cd noctis_app
flutter pub get
flutter run
```

Демо-вход: введите любой номер в формате `+71234567890`, затем код `000000`.

## Развёртывание VPS

Подробности в [`deploy/README.md`](deploy/README.md). Кратко:

```bash
scp deploy/provision.sh root@79.137.162.27:/root/
ssh root@79.137.162.27
sudo DOMAIN=your-domain.com LE_EMAIL=you@your-domain.com bash /root/provision.sh
```

Скрипт идемпотентен и поднимает Docker, Nginx, PostgreSQL, Redis, MinIO, UFW, fail2ban, ежедневный cron-бэкап.

## Лицензия

[MIT](LICENSE).
