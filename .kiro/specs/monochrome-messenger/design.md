# Design Document — NOCTIS

## Overview

NOCTIS — премиальный кроссплатформенный мессенджер в строгой чёрно-белой эстетике. Документ описывает техническое решение, реализующее 64 функциональных требования и расширенный набор продуктовых функций (Requirement 65). Архитектура построена вокруг трёх контуров:

- **NOCTIS_App** — Flutter-приложение (iOS / Android), отвечающее за UI, локальное шифрованное хранение, оффлайн-очередь, сквозное шифрование Secret_Chat и WebRTC-клиент.
- **NOCTIS_Backend** — монолитный сервис на Go (Fiber + WebSocket), внутренне разбитый на изолированные модули (Auth, Messaging, Presence, Media, Calls, Notifications), что позволяет начать с одной бинарной поставки и при необходимости вынести модули в отдельные процессы без изменения публичных контрактов.
- **Инфраструктура** — единый VPS Ubuntu 22.04 (IP `79.137.162.27`), оркестрируемый Docker Compose, с Nginx в качестве TLS-терминатора и обратного прокси, PostgreSQL 15 для постоянного хранения, Redis 7 для presence/pub-sub/refresh-токенов, MinIO для медиа, coturn для STUN/TURN.

CI/CD реализован GitHub Actions: при пуше в `main` собирается релизный APK, подписывается ключом из секретов и публикуется в GitHub Releases с тегом `vYYYYMMDD-<sha7>`.

Ключевые архитектурные принципы:

1. **Сквозная типизация контрактов**. WebSocket-протокол описан JSON Schema, REST — OpenAPI 3.1; оба контракта валидируются в CI и используются для генерации Dart/Go-моделей.
2. **Оффлайн-первый клиент**. Локальная зашифрованная БД (Drift + SQLCipher) — основной источник правды для UI; сетевая синхронизация — фоновый процесс, не блокирующий пользовательские сценарии.
3. **Идемпотентность доставки**. Каждое исходящее сообщение имеет `client_message_id` (UUIDv7); сервер использует его как ключ дедупликации.
4. **Изоляция Secret_Chat**. Сервер не имеет доступа к открытому тексту секретных сообщений, push-уведомления редактируются (R16.6).
5. **Монохромный инвариант**. Все цветовые токены проходят через `Theme_Engine`, который рантайм-валидирует принадлежность палитре `#000000`–`#FFFFFF` (R39.4).

## Architecture

### Контекстная диаграмма

```mermaid
flowchart LR
    subgraph Mobile[Пользовательские устройства]
        IOS[iOS Client<br/>NOCTIS_App]
        AND[Android Client<br/>NOCTIS_App]
    end

    subgraph VPS["VPS Ubuntu 22.04 (79.137.162.27)"]
        NGINX[Nginx<br/>TLS 1.2/1.3<br/>:80/:443]
        BACKEND[NOCTIS_Backend<br/>Go + Fiber + WS]
        PG[(PostgreSQL 15)]
        REDIS[(Redis 7)]
        MINIO[MinIO<br/>S3-совместимое<br/>хранилище медиа]
        TURN[coturn<br/>STUN/TURN]
        PROM[Prometheus]
        GRAF[Grafana]
    end

    subgraph External[Внешние сервисы]
        SMS[SMS-провайдер]
        SMTP[SMTP-сервер]
        FCM[Firebase Cloud<br/>Messaging]
        APNS[Apple Push<br/>Notification Service]
        LE[Let's Encrypt]
        GH[GitHub Actions<br/>CI/CD]
    end

    IOS -- HTTPS/WSS --> NGINX
    AND -- HTTPS/WSS --> NGINX
    IOS -- WebRTC SRTP --> TURN
    AND -- WebRTC SRTP --> TURN

    NGINX --> BACKEND
    BACKEND --> PG
    BACKEND --> REDIS
    BACKEND --> MINIO
    BACKEND --> TURN
    BACKEND --> SMS
    BACKEND --> SMTP
    BACKEND --> FCM
    BACKEND --> APNS

    BACKEND -- /metrics --> PROM
    PROM --> GRAF

    NGINX -. ACME .-> LE
    GH -- deploy<br/>(опционально) --> VPS
    GH -- publish APK --> Releases[(GitHub Releases)]
```

### Декомпозиция NOCTIS_Backend на сервисы

Внутренние сервисы разделены по доменам, общаются через интерфейсы внутри одного процесса (на старте) и через Redis Pub/Sub при горизонтальном масштабировании.

```mermaid
flowchart TB
    subgraph Backend[NOCTIS_Backend]
        TR[Transport Layer<br/>HTTP/WebSocket]
        AUTH[Auth_Service<br/>JWT, Argon2id, OTP]
        MSG[Messaging_Service<br/>WS-fanout, история]
        PRES[Presence_Service<br/>online/typing]
        MED[Media_Service<br/>upload/stream/transcode]
        CALL[Call_Service<br/>WebRTC signaling]
        NOTIF[Notification_Service<br/>FCM/APNs]
    end

    TR --> AUTH
    TR --> MSG
    TR --> PRES
    TR --> MED
    TR --> CALL
    AUTH --> NOTIF
    MSG --> NOTIF
    MSG <--> PRES
    CALL --> NOTIF
```

| Сервис | Ответственность | Хранилища |
| --- | --- | --- |
| Auth_Service | Регистрация (SMS/email), верификация OTP, выпуск JWT и refresh-токенов, облачный пароль (Argon2id), управление сессиями (R1–R4, R38) | PostgreSQL: `users`, `sessions`, `devices`. Redis: OTP, счётчики попыток, refresh-токены |
| Messaging_Service | Прямые чаты, история, редактирование/удаление, реакции, ответы, исчезающие сообщения, черновики, поиск (R7–R11, R20, R22, R29) | PostgreSQL: `messages`, `message_edits`, `message_reactions`, `drafts`. Redis: pub/sub-каналы по `chat_id` |
| Presence_Service | Онлайн-статусы, индикаторы набора, время «был в сети» с уважением приватности (R8, R35.2) | Redis: `presence:{user_id}`, `typing:{chat_id}` |
| Media_Service | Чанковая загрузка, SHA-256, миниатюры, транскрибация, потоковая выдача с Range Requests (R5.4, R13, R14) | MinIO; PostgreSQL: `attachments` |
| Call_Service | WebRTC-сигналинг (offer/answer/ICE), интеграция с coturn, история звонков (R15) | PostgreSQL: `calls`. Redis: pub/sub call-rooms |
| Notification_Service | Регистрация push-токенов, доставка через FCM/APNs, тихие/важные/Secret_Chat-редактированные уведомления (R16) | PostgreSQL: `push_tokens` |

### Топология развёртывания

Единый VPS Ubuntu 22.04 LTS, IP `79.137.162.27`. Все сервисы — контейнеры, запущенные через Docker Compose; Nginx — единственная точка входа на порты 80/443.

```mermaid
flowchart LR
    subgraph Host[Ubuntu 22.04 LTS · 4 vCPU · 8 GB RAM]
        UFW[UFW: 22, 80, 443]
        FAIL[fail2ban]
        subgraph DC[docker compose]
            NG[nginx]
            BE[backend]
            PG[(postgres)]
            RD[(redis)]
            MN[minio]
            CT[coturn]
            PRM[prometheus]
            GR[grafana]
        end
        CRON[cron: pg_dump<br/>ежедневно]
        VOL_PG[(/var/lib/noctis/pg)]
        VOL_RD[(/var/lib/noctis/redis)]
        VOL_MN[(/var/lib/noctis/minio)]
        VOL_BK[(/var/backups/noctis)]
    end
    NG --> BE
    BE --> PG
    BE --> RD
    BE --> MN
    BE --> CT
    PG -.-> VOL_PG
    RD -.-> VOL_RD
    MN -.-> VOL_MN
    CRON --> VOL_BK
    PRM --> BE
    GR --> PRM
```

TLS-сертификат выпускается Let's Encrypt через `certbot` с автоматическим продлением (R53.2). Nginx проксирует HTTPS → HTTP на `backend:8080`, WSS → WS на тот же контейнер с заголовками `Upgrade`/`Connection`. HSTS включён со значением `max-age=31536000; includeSubDomains; preload`.

## Components and Interfaces

### NOCTIS_App (Flutter)

#### Структура проекта

```
noctis_app/
├── lib/
│   ├── core/                # переиспользуемые абстракции
│   │   ├── crypto/          # X3DH, Double Ratchet (libsignal-protocol-dart)
│   │   ├── network/         # WebSocket-клиент, HTTP-клиент, retry/backoff
│   │   ├── storage/         # Drift + SQLCipher, KeyStore/Keychain
│   │   ├── theme/           # Theme_Engine, Monochrome_Palette guard
│   │   ├── animation/       # UI_Engine: кривые, длительности, haptics
│   │   ├── parser/          # парсер форматирования (R64)
│   │   ├── protocol/        # WebSocket envelope, JSON Schema (R63)
│   │   └── utils/
│   ├── features/            # вертикальные срезы (один каталог = один use-case)
│   │   ├── auth/
│   │   ├── chats/
│   │   ├── messages/
│   │   ├── secret_chat/
│   │   ├── calls/
│   │   ├── media/
│   │   ├── stickers/
│   │   ├── mini_tools/
│   │   ├── tags/
│   │   ├── folders/
│   │   ├── search/
│   │   ├── settings/
│   │   └── notifications/
│   ├── data/                # репозитории и DTO
│   │   ├── repositories/
│   │   ├── models/
│   │   └── sync/            # offline-очередь, синхронизатор
│   ├── ui/                  # переиспользуемые виджеты, экраны-каркасы
│   │   ├── widgets/
│   │   ├── screens/
│   │   └── transitions/
│   ├── app.dart
│   └── main.dart
├── test/                    # unit + widget
├── integration_test/        # E2E
└── pubspec.yaml
```

#### Управление состоянием

Выбран **Riverpod 2.x** (code-generation):

- Иммутабельность состояния, глобальная инспектируемость, тестируемость без `BuildContext`.
- Прозрачное разделение `Provider` (read-only), `StateNotifier` (запись), `AsyncNotifier` (async-данные с состоянием загрузки/ошибки).
- Лучшая совместимость с Drift и WebSocket-стримами через `StreamProvider`.

Альтернатива BLoC рассмотрена, но отклонена из-за лишней церемонии (event/state-классы) при работе с потоками сообщений и событиями WebSocket.

Слои данных:

- `MessageRepository` — единственный API для UI, инкапсулирует Drift + сетевой синхронизатор.
- `WebSocketClient` — синглтон, экспортирует `Stream<ServerEvent>` и `Sink<ClientEvent>`.
- `OutboxQueue` — Drift-таблица отложенных операций (отправка, редактирование, удаление, реакции).

#### Theme_Engine (R39, R43.3)

```mermaid
flowchart LR
    UI[Виджет] --> TT[ThemeTokens]
    TT --> Pal[MonochromePalette<br/>сторадж RGB]
    Pal --> Guard{contains?}
    Guard -- да --> Render[Render]
    Guard -- нет --> Warn[devLogger.warn<br/>+ блокировка<br/>R39.4]
    Settings[SettingsService] -- активная тема --> TT
    OS[Platform.brightness] -- авто-режим --> TT
```

Особенности:

- 4 встроенные темы как наборы токенов: Pure Black, Pure White, Graphite, Paper. Все цвета — оттенки серого `#RRGGBB` где `R == G == B`.
- Любой `Color` перед использованием в виджете проходит через `MonochromePalette.assertGrayscale(c)`. В debug-сборке нарушение — ошибка; в release — лог уровня `warn` и подмена на ближайший серый (`#808080`).
- Переключение темы: `AnimatedTheme` с длительностью 300 мс и кривой `Curves.easeInOutCubic` (R39.3).
- Авто-режим подписывается на `MediaQuery.platformBrightness` (R39.5).

#### UI_Engine (R40–R42)

- Базовый набор констант: длительности `Durations.tap = 100ms`, `Durations.list = 300ms`, `Durations.screen = 300ms`; кривая `Curves.easeOutCubic` (∼ `cubic-bezier(0.4, 0.0, 0.2, 1)`).
- `HapticsService` — обёртка над `HapticFeedback.lightImpact/mediumImpact/heavyImpact/error`. Перед вызовом проверяется `await Vibration.hasVibrator()` (R42.4).
- Глобальный `PerformanceMonitor` логирует кадры дольше 16.7 мс через `SchedulerBinding.addTimingsCallback` для отладки 60fps-цели.
- Режим «Уменьшить движение» подменяет все `AnimatedSwitcher`/`AnimatedContainer` на cross-fade ≤ 100 мс (R40.6).

#### Локальное шифрованное хранилище (R45)

- **Drift** + **SQLCipher** (`drift_sqflite` + `sqflite_sqlcipher`).
- Ключ БД генерируется при первом запуске (32 байта из `Random.secure()`), оборачивается в KeyStore (Android, `MasterKey.AES256_GCM`) или Keychain (iOS, `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`); если пользователь включил «Защита приложения», к ключу добавляется biometric prompt (R45.4, R46).
- Локально хранятся: последние 1000 сообщений на чат, контакты, наборы стикеров, черновики, очередь оффлайн, настройки, отпечатки ключей Secret_Chat.
- Шифрование экспорта (R37.2) — AES-256-GCM, ключ — PBKDF2-HMAC-SHA256(пароль, salt=16B, iter=200000).

#### Crypto_Module (R12)

```mermaid
sequenceDiagram
    participant A as Алиса (App)
    participant S as Backend
    participant B as Боб (App)
    A->>S: publish_prekey_bundle (IK_pub, SPK_pub, OPK_pub[])
    Note over A,S: Сервер хранит только публичные ключи
    A->>S: GET prekey_bundle(B)
    S-->>A: IK_pub_B, SPK_pub_B, OPK_pub_B
    A->>A: X3DH → SK
    A->>A: Double Ratchet (root, chain)
    A->>S: secret_message{ciphertext, header}
    S->>B: forward(ciphertext, header)
    B->>B: decrypt + ratchet
```

- Используется `libsignal_protocol_dart`. Хранилище ключей — отдельная Drift-таблица `signal_keys` в той же зашифрованной БД.
- Отпечаток ключа (R12.5) — SHA-256 от Identity Key Bob ⊕ Identity Key Alice, отображается группами по 5 цифр; QR-код кодирует тот же отпечаток (Base32, без пробелов).
- При смене Identity Key собеседника (R12.6) `SecretChatRepository` поднимает событие `IdentityChanged` и UI блокирует отправку до подтверждения.
- Secret_Chat привязан к `device_id` (R12.4): таблица `chats.kind = 'secret'`, поле `device_scope_id` ссылается на конкретное устройство.

#### Оффлайн-очередь и синхронизация (R45)

```mermaid
sequenceDiagram
    participant UI
    participant Repo as MessageRepository
    participant Out as OutboxQueue (Drift)
    participant WS as WebSocketClient
    participant Server
    UI->>Repo: send(text)
    Repo->>Out: insert(op{client_message_id, ...})
    Repo-->>UI: optimistic message (status=sending)
    alt онлайн
        Out->>WS: send envelope
        WS->>Server: message.send
        Server-->>WS: message.ack(server_id)
        WS->>Out: mark sent
    else офлайн
        Note over Out: ждём NetworkState.online
    end
```

Свойства:

- Каждая запись Outbox имеет `client_message_id` (UUIDv7) — он же ключ идемпотентности на сервере (R7.4).
- Порядок отправки соблюдается per-chat: внутри одной БД-транзакции в очередь добавляется монотонная локальная позиция.
- При получении `message.ack` локальное сообщение получает финальный `server_message_id` без перерисовки (тот же объект в Drift).

### NOCTIS_Backend (Go)

#### Структура модулей

```
noctis_backend/
├── cmd/
│   └── noctis/                 # main.go: бутстрап, чтение env, graceful shutdown
├── internal/
│   ├── auth/                   # OTP, JWT, Argon2id, sessions
│   ├── messaging/              # отправка, редакт., удаление, исчезающие, история
│   ├── presence/               # online, typing
│   ├── media/                  # chunked upload, MinIO, transcode, transcribe
│   ├── calls/                  # WebRTC signaling
│   ├── notifications/          # FCM/APNs, редактирование Secret_Chat-push
│   ├── transport/              # HTTP-роутер (Fiber), WS-hub, JSON Schema валидатор
│   ├── protocol/               # сгенерированные DTO + парсер/сериализатор (R63)
│   ├── storage/
│   │   ├── postgres/           # пул, миграции (goose)
│   │   ├── redis/              # клиент, scripts (Lua для атомарных операций)
│   │   └── minio/
│   ├── ratelimit/              # token bucket, per-user/per-IP
│   ├── observability/          # zerolog (JSON), Prometheus client
│   └── config/                 # парсинг ENV, валидация
├── api/
│   ├── openapi.yaml            # OpenAPI 3.1
│   └── ws-schema.json          # JSON Schema протокола WS
├── migrations/                 # *.sql, версионируется goose
├── deploy/
│   ├── docker-compose.yml
│   ├── Dockerfile
│   ├── nginx/noctis.conf
│   └── provision.sh
└── go.mod
```

#### WebSocket-протокол

Транспорт — WSS поверх Nginx (`/ws`). После успешного `Upgrade` клиент в течение 5 с шлёт фрейм `auth` с access-токеном, иначе сервер закрывает соединение (`code=4401`).

**Конверт сообщения** (одинаков для входящих и исходящих, валидируется JSON Schema):

```json
{
  "v": 1,
  "id": "01J9V0X4...",            // ULID/UUIDv7, уникален в рамках соединения
  "type": "message.send",         // см. таблицу типов
  "ts": "2025-01-15T12:34:56Z",   // RFC 3339
  "ref_id": null,                  // для ответов: id запроса
  "payload": { ... }
}
```

| Тип | Направление | Назначение |
| --- | --- | --- |
| `auth` | C→S | Аутентификация соединения |
| `auth.ok` / `auth.fail` | S→C | Результат |
| `message.send` | C→S | Отправка (идемпотентно по `payload.client_message_id`) |
| `message.ack` | S→C | Подтверждение приёма сервером |
| `message.new` | S→C | Доставка нового сообщения подписчику |
| `message.edit` | C→S, S→C | Редактирование (R10.1) |
| `message.delete` | C→S, S→C | Удаление (R10.3, R10.4) |
| `message.reaction` | C→S, S→C | Реакция (R20) |
| `typing.start` / `typing.stop` | C→S, S→C | R8.1–R8.3 |
| `presence.update` | S→C | Изменение статуса контакта |
| `read_receipt` | C→S, S→C | R7.6, R27.2 |
| `secret.message` | C→S, S→C | Зашифрованный конверт Secret_Chat |
| `call.offer` / `call.answer` / `call.ice` / `call.end` | C↔S | WebRTC сигналинг |
| `error` | S→C | Контролируемые ошибки протокола |

JSON Schema (фрагмент, payload-схемы дискриминируются полем `type`):

```json
{
  "$id": "https://noctis.app/schema/ws.json",
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "type": "object",
  "required": ["v", "id", "type", "ts", "payload"],
  "properties": {
    "v": { "const": 1 },
    "id": { "type": "string", "pattern": "^[0-9A-HJKMNP-TV-Z]{26}$|^[0-9a-f-]{36}$" },
    "type": { "type": "string" },
    "ts": { "type": "string", "format": "date-time" },
    "ref_id": { "type": ["string", "null"] },
    "payload": { "type": "object" }
  },
  "$defs": { "MessageSend": { /* ... */ } }
}
```

Парсер/сериализатор (R63) реализуется как пара функций `Parse([]byte) (Envelope, error)` и `Serialize(Envelope) ([]byte, error)`. Обе используют `xeipuuv/gojsonschema` для валидации против `ws-schema.json`. Round-trip-инвариант (R63.3) обеспечивается отсутствием поля `unknown` (любые лишние ключи отвергаются `additionalProperties: false`).

#### REST API (OpenAPI 3.1)

Базовый префикс `/api/v1`. Перечень основных эндпоинтов:

| Метод | Путь | Назначение |
| --- | --- | --- |
| `POST` | `/auth/phone/start` | Запросить SMS-код (R1.1, лимит R54.1) |
| `POST` | `/auth/phone/verify` | Подтвердить код, получить токены (R1.2) |
| `POST` | `/auth/email/start` | Запросить email-ссылку (R2.1) |
| `GET`  | `/auth/email/verify` | Подтверждение по ссылке (R2.2) |
| `POST` | `/auth/cloud_password/set` | Установка/смена облачного пароля (R4) |
| `POST` | `/auth/cloud_password/verify` | Второй фактор после OTP |
| `POST` | `/auth/refresh` | Обмен refresh-токена (R3.2) |
| `GET`  | `/auth/sessions` | Список активных сессий (R3.3) |
| `DELETE` | `/auth/sessions/{id}` | Завершить сессию (R3.4) |
| `DELETE` | `/auth/sessions` | Завершить все сессии (R3.5) |
| `GET`  | `/me` | Профиль |
| `PATCH` | `/me` | Обновление профиля (R5) |
| `POST` | `/contacts/sync` | Синхронизация хешированных номеров (R6.1, R6.2) |
| `GET`  | `/chats` | Список чатов |
| `GET`  | `/chats/{id}/messages` | Пагинация истории (R9) |
| `POST` | `/chats/{id}/messages/search` | Полнотекстовый поиск (R9.4, R19.2) |
| `POST` | `/media/upload/init` | Инициация чанковой загрузки (R13.3) |
| `PUT`  | `/media/upload/{id}/chunk/{n}` | Чанк |
| `POST` | `/media/upload/{id}/complete` | Финализация, SHA-256 (R13.4) |
| `GET`  | `/media/{id}` | Стриминг с Range Requests (R13.6) |
| `GET`  | `/calls/turn-credentials` | Получение temporary credentials для coturn |
| `POST` | `/notifications/devices` | Регистрация push-токена (R16.1) |
| `GET`  | `/healthz` | Healthcheck (R47.4) |
| `GET`  | `/metrics` | Prometheus (R47.5) |

Спецификация валидируется в CI через `redocly lint api/openapi.yaml` и `swagger-cli validate`. Сборка проваливается при ошибках (R50.3).

#### Аутентификация и сессии

- **Access JWT**: HS256, payload `{sub, sid, did, exp, iat, scope}`, TTL 3600 с (R1.2). Подписывается секретом из `JWT_SECRET`. Поддерживается ротация: одновременно валидны два секрета (`JWT_SECRET_CURRENT`, `JWT_SECRET_PREVIOUS`); при ротации старый отключается через 24 часа.
- **Refresh-токен**: opaque-строка 256 бит из `crypto/rand`, в base64url. Хеш SHA-256 от токена хранится в Redis ключом `refresh:{hash}` со значением `{user_id, session_id, device_id}` и TTL 2 592 000 с (R1.2, R49.4). Plain-токен возвращается клиенту один раз.
- **Облачный пароль** (R4.1): Argon2id с параметрами `time=3, memory=64 MiB, parallelism=4, salt=16B, key=32B`. Соль уникальна на пользователя, хранится в `users.cloud_password_salt`.
- **Инвалидация** (R3.4–R3.6): удаление ключа `refresh:{hash}` из Redis + запись в `sessions.revoked_at`. Проверка при `/auth/refresh`: отсутствие ключа ⇒ `SESSION_INVALID`.

#### Стратегия rate-limiting (R54)

- Реализация — token bucket в Redis (Lua-скрипт для атомарности).
- Ключи:
  - `rl:auth:sms:ip:{ip}` — 3/час;
  - `rl:auth:sms:phone:{e164}` — 5/час;
  - `rl:auth:otp:phone:{e164}` — 5 неуспешных за 600 с ⇒ блок 900 с (R1.4);
  - `rl:msg:user:{user_id}` — 30 сообщений/с (R54.2);
  - `rl:cloud_pwd:user:{user_id}` — 10 неуспешных ⇒ блок 3600 с (R4.4).
- При превышении API возвращает HTTP 429 с заголовком `Retry-After` (R54.3); WebSocket — `error{code: "RATE_LIMITED", retry_after_ms}`.

## Data Models

### PostgreSQL — схема

Идентификаторы — `BIGINT GENERATED ALWAYS AS IDENTITY` (для строго возрастающих суррогатов) и `UUID` (для внешних идентификаторов), временные метки — `TIMESTAMPTZ`.

```sql
-- Пользователи
CREATE TABLE users (
  id                BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  uuid              UUID NOT NULL UNIQUE DEFAULT gen_random_uuid(),
  phone_e164        TEXT UNIQUE,
  email             TEXT UNIQUE,
  email_verified    BOOLEAN NOT NULL DEFAULT FALSE,
  display_name      TEXT NOT NULL CHECK (char_length(display_name) BETWEEN 1 AND 64),
  username          TEXT UNIQUE CHECK (username ~ '^[a-z0-9_]{5,32}$'),
  status_text       TEXT CHECK (char_length(status_text) <= 140),
  avatar_attachment_id BIGINT,
  cloud_password_hash TEXT,
  cloud_password_salt BYTEA,
  privacy           JSONB NOT NULL DEFAULT '{}'::jsonb, -- R35: phone/avatar/calls/forwards
  deleted_at        TIMESTAMPTZ,
  inactive_purge_after INTERVAL,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Сессии и устройства
CREATE TABLE devices (
  id            BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  user_id       BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  device_uid    TEXT NOT NULL,           -- стабильный ID от клиента
  platform      TEXT NOT NULL,           -- ios|android
  os_version    TEXT,
  model         TEXT,
  app_version   TEXT,
  signal_identity_pub BYTEA,             -- для Secret_Chat (R12)
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(user_id, device_uid)
);

CREATE TABLE sessions (
  id              BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  user_id         BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  device_id       BIGINT NOT NULL REFERENCES devices(id) ON DELETE CASCADE,
  refresh_hash    BYTEA NOT NULL UNIQUE,   -- SHA-256 от plain refresh
  ip_inet         INET,
  geo_region      TEXT,
  user_agent      TEXT,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  last_active_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  revoked_at      TIMESTAMPTZ
);
CREATE INDEX idx_sessions_user_active ON sessions(user_id) WHERE revoked_at IS NULL;

-- Контакты
CREATE TABLE contacts (
  owner_id   BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  contact_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  alias      TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY(owner_id, contact_id)
);

-- Чаты
CREATE TYPE chat_kind AS ENUM ('direct','secret','saved','group','channel');

CREATE TABLE chats (
  id               BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  uuid             UUID NOT NULL UNIQUE DEFAULT gen_random_uuid(),
  kind             chat_kind NOT NULL,
  title            TEXT,
  device_scope_id  BIGINT REFERENCES devices(id), -- только для secret (R12.4)
  ttl_seconds      INTEGER,                       -- R11.2 текущее значение TTL чата
  created_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE chat_members (
  chat_id    BIGINT NOT NULL REFERENCES chats(id) ON DELETE CASCADE,
  user_id    BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  role       TEXT NOT NULL DEFAULT 'member',     -- member|admin|owner
  joined_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  archived   BOOLEAN NOT NULL DEFAULT FALSE,
  pinned     BOOLEAN NOT NULL DEFAULT FALSE,
  muted_until TIMESTAMPTZ,
  read_up_to_seq BIGINT NOT NULL DEFAULT 0,
  PRIMARY KEY(chat_id, user_id)
);

-- Сообщения
CREATE TYPE message_kind AS ENUM ('text','image','video','audio','voice','file','sticker','location','contact_card','poll','call_event','system');

CREATE TABLE messages (
  id                  BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  chat_id             BIGINT NOT NULL REFERENCES chats(id) ON DELETE CASCADE,
  seq                 BIGINT NOT NULL,                -- монотонно возрастающий в пределах chat_id (R7.2)
  sender_id           BIGINT NOT NULL REFERENCES users(id),
  client_message_id   UUID NOT NULL,                  -- идемпотентность (R7.4)
  kind                message_kind NOT NULL,
  body_text           TEXT CHECK (body_text IS NULL OR char_length(body_text) <= 4096),
  body_ciphertext     BYTEA,                          -- для secret (R12.3)
  reply_to_message_id BIGINT REFERENCES messages(id),
  forward_from_user_id BIGINT REFERENCES users(id),
  ttl_seconds         INTEGER,                        -- snapshot (R11.4)
  read_at             TIMESTAMPTZ,
  expires_at          TIMESTAMPTZ,                    -- = read_at + ttl (R11.3)
  edited_at           TIMESTAMPTZ,
  deleted_for_all_at  TIMESTAMPTZ,
  scheduled_for       TIMESTAMPTZ,                    -- R25
  created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(chat_id, seq),
  UNIQUE(chat_id, sender_id, client_message_id)       -- идемпотентность
);
CREATE INDEX idx_messages_chat_created   ON messages(chat_id, created_at DESC); -- R48.3
CREATE INDEX idx_messages_chat_id_id     ON messages(chat_id, id DESC);
CREATE INDEX idx_messages_sender         ON messages(sender_id);                -- R48.3
CREATE INDEX idx_messages_expires        ON messages(expires_at) WHERE expires_at IS NOT NULL;
CREATE INDEX idx_messages_scheduled      ON messages(scheduled_for) WHERE scheduled_for IS NOT NULL;
CREATE INDEX idx_messages_fts            ON messages USING GIN (to_tsvector('simple', coalesce(body_text,'')));
CREATE INDEX idx_messages_fts_ru         ON messages USING GIN (to_tsvector('russian', coalesce(body_text,'')));
CREATE INDEX idx_messages_fts_en         ON messages USING GIN (to_tsvector('english', coalesce(body_text,'')));

-- История правок (R10.5)
CREATE TABLE message_edits (
  message_id BIGINT NOT NULL REFERENCES messages(id) ON DELETE CASCADE,
  edited_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  prev_body  TEXT,
  PRIMARY KEY(message_id, edited_at)
);

-- Реакции (R20)
CREATE TABLE message_reactions (
  message_id BIGINT NOT NULL REFERENCES messages(id) ON DELETE CASCADE,
  user_id    BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  emoji      TEXT NOT NULL CHECK (char_length(emoji) <= 16),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY(message_id, user_id, emoji)
);

-- Вложения (R13)
CREATE TABLE attachments (
  id            BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  message_id    BIGINT REFERENCES messages(id) ON DELETE CASCADE,
  uploader_id   BIGINT NOT NULL REFERENCES users(id),
  bucket        TEXT NOT NULL,
  object_key    TEXT NOT NULL,
  mime_type     TEXT NOT NULL,
  size_bytes    BIGINT NOT NULL CHECK (size_bytes >= 0 AND size_bytes <= 2199023255552),
  sha256        BYTEA NOT NULL,
  width         INTEGER,
  height        INTEGER,
  duration_ms   INTEGER,
  thumbnail_key TEXT,
  transcript    TEXT,
  transcript_lang TEXT,
  transcript_confidence REAL,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(bucket, object_key)
);
CREATE INDEX idx_attachments_message ON attachments(message_id);

-- Черновики (R22)
CREATE TABLE drafts (
  user_id     BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  chat_id     BIGINT NOT NULL REFERENCES chats(id) ON DELETE CASCADE,
  body_text   TEXT NOT NULL,
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY(user_id, chat_id)
);

-- Smart_Tag (R17), Папки (R18)
CREATE TABLE smart_tags (
  id        BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  owner_id  BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name      TEXT NOT NULL CHECK (char_length(name) BETWEEN 1 AND 24),
  auto      BOOLEAN NOT NULL DEFAULT FALSE,
  UNIQUE(owner_id, name)
);
CREATE TABLE chat_tags (
  chat_id BIGINT NOT NULL REFERENCES chats(id) ON DELETE CASCADE,
  tag_id  BIGINT NOT NULL REFERENCES smart_tags(id) ON DELETE CASCADE,
  PRIMARY KEY(chat_id, tag_id)
);
CREATE TABLE folders (
  id       BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  owner_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name     TEXT NOT NULL,
  position INTEGER NOT NULL,
  filter   JSONB NOT NULL
);

-- Стикеры (R23)
CREATE TABLE sticker_sets (
  id          BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  owner_id    BIGINT REFERENCES users(id),
  title       TEXT NOT NULL,
  invite_slug TEXT UNIQUE,
  built_in    BOOLEAN NOT NULL DEFAULT FALSE
);
CREATE TABLE stickers (
  id            BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  set_id        BIGINT NOT NULL REFERENCES sticker_sets(id) ON DELETE CASCADE,
  attachment_id BIGINT NOT NULL REFERENCES attachments(id),
  emoji         TEXT
);

-- Опросы (R34)
CREATE TABLE polls (
  message_id BIGINT PRIMARY KEY REFERENCES messages(id) ON DELETE CASCADE,
  question   TEXT NOT NULL CHECK (char_length(question) BETWEEN 1 AND 256),
  options    JSONB NOT NULL,
  multi      BOOLEAN NOT NULL DEFAULT FALSE,
  anonymous  BOOLEAN NOT NULL DEFAULT FALSE,
  quiz       BOOLEAN NOT NULL DEFAULT FALSE,
  correct_idx INTEGER,
  explanation TEXT
);

-- Звонки (R15)
CREATE TYPE call_kind AS ENUM ('audio','video');
CREATE TYPE call_status AS ENUM ('ringing','active','ended','missed','declined');
CREATE TABLE calls (
  id          BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  chat_id     BIGINT NOT NULL REFERENCES chats(id) ON DELETE CASCADE,
  caller_id   BIGINT NOT NULL REFERENCES users(id),
  callee_id   BIGINT NOT NULL REFERENCES users(id),
  kind        call_kind NOT NULL,
  status      call_status NOT NULL,
  started_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  ended_at    TIMESTAMPTZ,
  duration_ms INTEGER
);

-- Блокировки (R35.1)
CREATE TABLE blocks (
  blocker_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  blocked_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY(blocker_id, blocked_id)
);

-- Push-токены (R16.1)
CREATE TABLE push_tokens (
  id          BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  device_id   BIGINT NOT NULL UNIQUE REFERENCES devices(id) ON DELETE CASCADE,
  platform    TEXT NOT NULL,             -- fcm|apns
  token       TEXT NOT NULL,
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Аудит (модерация, R36; критические операции, R3, R38)
CREATE TABLE audit_log (
  id         BIGSERIAL PRIMARY KEY,
  actor_id   BIGINT REFERENCES users(id),
  action     TEXT NOT NULL,
  target     JSONB,
  ip_inet    INET,
  user_agent TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
```

Поле `messages.seq` назначается атомарно через PostgreSQL-транзакцию вида:

```sql
WITH next AS (
  SELECT COALESCE(MAX(seq), 0) + 1 AS s FROM messages WHERE chat_id = $1 FOR UPDATE
)
INSERT INTO messages (chat_id, seq, ...) SELECT $1, s, ... FROM next
ON CONFLICT (chat_id, sender_id, client_message_id) DO UPDATE SET edited_at = messages.edited_at
RETURNING id, seq;
```

`ON CONFLICT (chat_id, sender_id, client_message_id) DO UPDATE` — вырожденный апдейт для возврата существующего ряда без создания дубликата (R7.4).

### Redis — ключи и TTL

| Префикс | Назначение | Тип | TTL |
| --- | --- | --- | --- |
| `presence:{user_id}` | Признак онлайн (R8.4) | STRING `1` | 90 с (R49.2) |
| `last_seen:{user_id}` | Последняя активность | STRING ts | 30 суток |
| `typing:{chat_id}` | Set активных «печатающих» | SET (members = user_id) | 6 с (через `EXPIRE` после каждого `typing.start`) |
| `otp:phone:{e164}` | Хеш OTP-кода | STRING | 300 с (R1.2) |
| `email_token:{token}` | Кандидат email-подтверждения | STRING | 1800 с (R2.1) |
| `refresh:{sha256}` | Активные refresh-токены | HASH | 2 592 000 с (R3, R49.4) |
| `rl:auth:sms:ip:{ip}` | Token bucket SMS по IP | STRING (count) | 3600 с |
| `rl:auth:sms:phone:{e164}` | Token bucket SMS по номеру | STRING | 3600 с |
| `rl:auth:otp:phone:{e164}` | Счётчик неуспешных OTP | STRING | 600 с / 900 с при блоке |
| `rl:msg:user:{user_id}` | Token bucket сообщений | STRING (tokens) | TTL refresh-on-write |
| `rl:cloud_pwd:user:{user_id}` | Счётчик неуспешных облачного пароля | STRING | 3600 с |
| `chat_chan:{chat_id}` | Pub/Sub канал маршрутизации между инстансами (R49.3) | PUBSUB | — |
| `user_chan:{user_id}` | Pub/Sub канал пользователя | PUBSUB | — |
| `call_room:{call_id}` | Состояние сигналинга | HASH | 7200 с |
| `expiring_msg:zset` | ZSET сообщений с TTL (score = epoch_ms expires_at) | ZSET | — |

`expiring_msg:zset` — индекс для воркера-удалителя: горутина каждые 500 мс делает `ZRANGEBYSCORE 0 now`, удаляет сообщения транзакцией `BEGIN; DELETE FROM messages ... ; ZREM ... ; COMMIT;` и публикует `message.delete` в `chat_chan:{chat_id}`. Это даёт точность ±2 с (R11.3) при шаге опроса 500 мс.

## Correctness Properties

*Свойство (property) — это характеристика или поведение, которое должно выполняться для всех валидных исполнений системы; формальное утверждение о том, что система обязана делать. Свойства соединяют человеко-читаемые требования с машинно-проверяемыми гарантиями корректности и реализуются как property-based-тесты с минимум 100 итерациями (для критичных протокольных — 500).*

После prework-анализа из 64 функциональных требований и 60 пунктов R65 выделены 14 универсальных свойств. Свойства, поглощающие более узкие частные случаи (например, все валидаторы длины), сгруппированы и явно перечисляют требования, которые они валидируют.

### Property 1: Round-trip парсера/сериализатора WebSocket-протокола

*Для любого* JSON-байт-блока `b`, валидного по `ws-schema.json`, выполняется `parse(serialize(parse(b))) == parse(b)` с точностью до канонизации (порядок ключей объекта не имеет значения, числа сохраняют точность); *для любого* envelope `e`, проходящего сериализацию, результат `serialize(e)` валидируется той же JSON Schema без ошибок; *для любого* `b`, не соответствующего схеме, парсер возвращает ошибку `PROTOCOL_VALIDATION_FAILED`.

**Validates: Requirements 63.1, 63.2, 63.3, 63.4**

### Property 2: Round-trip парсера форматирования сообщений

*Для любого* валидного дерева форматирования `T` с узлами из множества `{bold, italic, underline, strikethrough, monospace, spoiler, code_block, link, mention, hashtag, text}` выполняется `parse(serialize(T)) ≡ T` (структурное равенство с нормализацией подряд идущих текстовых узлов); *для любого* текста с синтаксической ошибкой разметки парсер возвращает дерево из единственного `text`-узла, а функция отправки сообщения остаётся доступной (не блокируется).

**Validates: Requirements 64.1, 64.2, 64.3, 64.4, 30.1, 30.3**

### Property 3: Идемпотентность отправки по client_message_id

*Для любых* `(user, chat, client_message_id, k ≥ 1)` и любой последовательности из `k` запросов `message.send` с одинаковым `client_message_id`, в таблице `messages` существует ровно одна строка с этим ключом, отправитель получает идентичный `server_message_id` во всех `k` ack-фреймах, и порядковый номер `seq` назначается ровно один раз.

**Validates: Requirements 7.4**

### Property 4: Монотонность и уникальность `seq` в чате

*Для любой* конкурентной последовательности успешных отправок сообщений `m₁..mₙ` в чат `c`, для всех `i < j` выполняется `seq(mᵢ) < seq(mⱼ)` если `mⱼ` подтверждён сервером после `mᵢ`, и `seq(mᵢ) ≠ seq(mⱼ)` для всех `i ≠ j` в пределах одного `chat_id`.

**Validates: Requirements 7.2**

### Property 5: TTL-снапшот и точность удаления исчезающих сообщений

*Для любого* сообщения `m`, отправленного в чат с активным TTL `t`, выполняется `m.ttl_seconds = t` (snapshot на момент отправки); *для любого* последующего изменения TTL чата на `t'` старые сообщения сохраняют исходный `t`; *для любого* `m`, прочитанного получателем в момент `r`, фактическое удаление наступает в интервале `[r + t − 2с, r + t + 2с]`; *для любого* допустимого выбора TTL значение принадлежит множеству `{5, 30, 60, 3600, 86400, 604800, 2592000}`.

**Validates: Requirements 11.1, 11.2, 11.3, 11.4**

### Property 6: Инвариант token-bucket для rate-limit

*Для любой* временно́й последовательности запросов `r₁..rₙ` к ограниченному ресурсу с параметрами `(limit L, window W, cooldown C)`, запрос `rₖ` принимается тогда и только тогда, когда количество принятых запросов в окне `[tₖ − W, tₖ]` строго меньше `L`; при превышении `L` сервер возвращает HTTP 429 с заголовком `Retry-After`, не превышающим `C`. Конкретные инстанциации: SMS по IP `(3, 1ч, 1ч)`; SMS по номеру `(5, 1ч, 1ч)`; OTP-попытки `(5, 600с, 900с)`; повторная отправка SMS `(1, 60с, 60с)`; повторное email-письмо `(1, 120с, 120с)`; облачный пароль `(10, ∞, 3600с)`; отправка сообщений `(30, 1с, динамический)`.

**Validates: Requirements 1.4, 1.5, 2.5, 4.4, 54.1, 54.2, 54.3**

### Property 7: Монохромная палитра (Theme_Engine confinement)

*Для любого* токена цвета `c`, передаваемого в любой виджет в рантайме, выполняется `red(c) == green(c) == blue(c)`; *для любого* цвета вне этого инварианта `Theme_Engine` отвергает рендеринг (debug — assert, release — подмена на `#808080` + warning) и не пропускает «случайно цветной» элемент в дерево виджетов.

**Validates: Requirements 39.1, 39.4**

### Property 8: Инвалидация refresh-токенов и сессий

*Для любых* множества активных сессий `S = {s₁..sₙ}` и любой выбранной для отзыва сессии `sᵢ`, после операции `DELETE /auth/sessions/{sᵢ.id}` (или `DELETE /auth/sessions` для массовой инвалидации, кроме текущей) выполняется: `refresh_hash(sᵢ)` отсутствует в Redis, `sessions.revoked_at` установлен; для всех `sⱼ`, не подвергшихся отзыву, токен остаётся валидным. *Для любой* refresh-байт-строки `b`, отсутствующей в Redis, `/auth/refresh(b)` возвращает `SESSION_INVALID`.

**Validates: Requirements 3.1, 3.4, 3.5, 3.6, 38.1**

### Property 9: Изоляция Secret_Chat (E2EE)

*Для любого* успешного обмена prekey-bundles между Алисой и Бобом X3DH-протокол выдаёт обеим сторонам идентичный shared secret `SK_a == SK_b`. *Для любого* сообщения `m`, отправленного в Secret_Chat, в таблице `messages` `body_text IS NULL` и `body_ciphertext IS NOT NULL`; в любом байте, передаваемом по WebSocket после успешной установки канала, plaintext исходного сообщения не встречается как подстрока. *Для любого* push-уведомления, относящегося к Secret_Chat, и для любой жалобы на сообщение Secret_Chat сервер не получает и не пересылает plaintext. *Для любого* Secret_Chat поле `chats.device_scope_id` ссылается на устройство-инициатор; пересылка из Secret_Chat в любой другой чат отвергается. *Для любой* пары identity-ключей `(IK_a, IK_b)` функция `fingerprint` детерминирована и удовлетворяет `fingerprint(IK_a, IK_b) == fingerprint(IK_b, IK_a)`; флаг предупреждения о смене ключа возникает тогда и только тогда, когда `fingerprint_old != fingerprint_new`.

**Validates: Requirements 12.1, 12.2, 12.3, 12.4, 12.5, 12.6, 12.7, 16.6, 21.3, 36.3**

### Property 10: FSM статусов сообщения

*Для любого* сообщения `m` его статус во времени образует допустимую цепочку переходов в графе `{sending → sent → delivered → read}` с альтернативой `sending → failed`; обратные переходы (например, `read → sent`) не наблюдаются ни в одной трассе. Если `read_receipts_disabled = true` для получателя, переход `delivered → read` не происходит на стороне отправителя.

**Validates: Requirements 27.1, 27.3**

### Property 11: Целостность медиа-загрузки

*Для любого* файла `F` и любого его разбиения на чанки `c₁..cₘ`, доставленных в произвольном порядке с пропусками и повторами (с возобновлением до полного покрытия), выполняется: `server_sha256 == sha256(F)`, `attachments.size_bytes == |F|`, и для любого валидного `Range: bytes=a-b` ответ `GET /media/{id}` возвращает `F[a..b]` с заголовком `Content-Range`. *Для любого* размера `s`: загрузка принимается тогда и только тогда, когда `s ≤ 2 048 МиБ`. *Для любого* изображения после клиентского сжатия `max(width, height) ≤ 2560`.

**Validates: Requirements 13.1, 13.2, 13.3, 13.4, 13.6**

### Property 12: Privacy-видимость профиля и присутствия

*Для любых* настроек приватности владельца `P ∈ {public, contacts, hidden}` для полей `phone`, `avatar`, `calls`, `forwards`, `last_seen` и любого зрителя `V` (контакт или нет, заблокирован или нет) ответ API `GET /users/{id}` и события Presence_Service содержат поле тогда и только тогда, когда `V` принадлежит разрешённой по `P` категории и `V` не находится в `blocks` владельца. Для `last_seen` при `P = hidden` точное время заменяется значением из множества `{recently, this_week, long_ago}`.

**Validates: Requirements 5.6, 8.6, 35.1, 35.2, 35.3, 35.4, 35.5, 35.6**

### Property 13: Bounded-length валидация

*Для любой* строки/массива `x` валидатор соответствующего поля принимает `x` тогда и только тогда, когда `min ≤ length(x) ≤ max`. Конкретные инстанциации:

| Поле / лимит | min | max | Источник |
| --- | --- | --- | --- |
| `display_name` | 1 | 64 символа | R5.1 |
| `username` | 5 | 32 символа | R5.2 |
| `status_text` | 0 | 140 символов | R5.5 |
| `message.body` (Direct_Chat) | 1 | 4096 символов | R7.1, R26.1 |
| `smart_tag.name` | 1 | 24 символа | R17.1 |
| `folders` (на пользователя) | 0 | 20 | R18.1 |
| `pinned chats` (на папку) | 0 | 10 | R18.3, R65.8 |
| `forward batch` | 1 | 100 сообщений | R21.4 |
| `poll.question` | 1 | 256 символов | R34.1 |
| `poll.options` | 2 | 10 вариантов | R34.1 |
| `attachment.size` | 0 | 2 048 МиБ | R13.1 |
| `sticker.size` | 0 | 512 КБ | R23.2 |
| `edit window` (часов с момента отправки) | 0 | 48 | R10.1, R10.2 |

**Validates: Requirements 5.1, 5.2, 5.5, 7.1, 10.1, 10.2, 13.1, 17.1, 18.1, 18.3, 21.4, 23.2, 26.1, 34.1, 65.8**

### Property 14: Идемпотентность provision-скрипта

*Для любого* начального состояния VPS `S₀` (чистый Ubuntu 22.04, частично подготовленный или уже полностью развёрнутый) и любого числа последовательных запусков `provision.sh` `N ≥ 1` итоговое наблюдаемое состояние системы `Sₙ` (установленные пакеты, конфиги Nginx, правила UFW, файлы Compose, наличие сертификата, запущенные контейнеры) удовлетворяет `Sₙ ≡ S₁` без дубликатов конфигураций и без ошибочных кодов выхода; при ошибке любой подкоманды скрипт прекращает выполнение и возвращает ненулевой код.

**Validates: Requirements 58.10, 58.11**


## Error Handling

### Контракт ошибок REST

Единый формат:

```json
{ "error": { "code": "INVALID_OTP", "message": "Code is invalid", "details": {} } }
```

| HTTP | code | Источник |
| --- | --- | --- |
| 400 | `VALIDATION_FAILED` | JSON Schema / OpenAPI |
| 401 | `AUTH_REQUIRED`, `SESSION_INVALID` (R3.6) | Auth_Service |
| 403 | `FORBIDDEN`, `BLOCKED_BY_USER` | Messaging |
| 409 | `USERNAME_TAKEN` (R5.3), `EDIT_WINDOW_EXPIRED` (R10.2) | — |
| 410 | `EMAIL_TOKEN_INVALID` (R2.4) | Auth |
| 422 | `INVALID_OTP` (R1.3), `CLOUD_PASSWORD_INVALID` (R4.3), `PROTOCOL_VALIDATION_FAILED` (R63.4) | Auth/Transport |
| 429 | `RATE_LIMITED` (R54.3) с `Retry-After` | RateLimiter |
| 500 | `INTERNAL` | catch-all |

### Контракт ошибок WebSocket

`error{code, message, ref_id?}` отправляется клиенту, **не закрывая** соединение, кроме фатальных случаев (`AUTH_REQUIRED`, `PROTOCOL_VALIDATION_FAILED` ⇒ закрытие с `code=4400`).

### Восстановление

- WebSocket-клиент: экспоненциальный backoff (1с, 2с, 4с, … до 30с) с jitter ±20%.
- Outbox: бесконечный retry с тем же backoff, пока сервер не вернёт `message.ack` или fatal-ошибку (`BLOCKED_BY_USER`, `CHAT_NOT_FOUND`).
- Парсер форматирования (R64.4): при синтаксической ошибке возвращает «сырой» текст-узел, не блокирует отправку.

## Testing Strategy

NOCTIS сочетает несколько уровней проверок. Property-based testing **применим** к подсистемам с универсальными инвариантами: парсер/сериализатор протокола (R63), парсер форматирования (R64), идемпотентность отправки (R7.4), монотонность `seq` (R7.2), TTL-удаление (R11.3), rate-limit-инварианты (R54), монохромная палитра (R39.4), инвалидация сессий (R3). Для остальных требований используются example-based, integration и UI-тесты.

### Уровни тестов

| Уровень | Инструменты | Что покрывает |
| --- | --- | --- |
| Unit (Dart) | `flutter_test`, `mocktail` | Pure-логика клиента: парсер форматирования, Theme_Engine guard, OutboxQueue |
| Unit (Go) | `testing`, `testify` | Auth, Messaging, парсер протокола, rate-limit |
| Property-based (Dart) | `glados` | R64 round-trip, Theme_Engine confinement |
| Property-based (Go) | `gopter` (или `testing/quick` для простых случаев) | R63, R7.2, R7.4, R11.3, R54, R3 |
| Widget-тесты (Dart) | `flutter_test` | Экраны входа, чата, настроек тем |
| Integration | docker-compose-в-CI | REST/WS-эндпоинты против реальных PG/Redis/MinIO |
| E2E (Flutter) | `integration_test` + Patrol | Сценарии регистрации → отправка → редактирование |
| Нагрузочные | `k6`, `wrk`, `tsung` | R47.2 (10k WS), R51 (1k msg/s) |
| Снимки UI | `golden_toolkit` | Темы Pure Black/White/Graphite/Paper |
| Безопасность | `gosec`, `dependabot`, `osv-scanner`, `flutter pub outdated` | R57.4 |

### Конфигурация property-тестов

- Минимум **100 итераций** на каждое свойство; критические (R63, R64) — **500**.
- Каждый property-тест помечается тегом-комментарием в формате:

```dart
// Feature: monochrome-messenger, Property 2: Forall valid formatting tree, serialize then parse equals original
```

```go
// Feature: monochrome-messenger, Property 1: Forall valid WS envelope, parse(serialize(parse(b))) == parse(b)
```

- Генераторы Dart/Go помещаются в `test/generators/` и `internal/.../testgen/`.
- Каждое свойство ссылается на номер из раздела «Correctness Properties».

### Покрытие требований

- R47.4, R47.5, R49 — smoke-тесты в CI после `docker compose up`.
- R39.1–R39.5 — комбинация property-тестов (R39.4) и golden-тестов остальных пунктов.
- R55–R57 — самопроверка CI: workflow тестируется на ветке `ci-test` ежемесячно.

## CI/CD дизайн

### Структура `.github/workflows/main.yml`

```mermaid
flowchart LR
    push[push на main] --> lint
    lint --> test
    test --> build_android
    build_android --> release
    push --> build_backend
    build_backend --> integration
```

| Job | Шаги | Артефакты |
| --- | --- | --- |
| `lint` | `actions/setup-flutter@v2` (версия из `pubspec.yaml`); `flutter pub get`; `flutter analyze`; `dart format --set-exit-if-changed .`; `golangci-lint run`; `redocly lint api/openapi.yaml`; `ajv validate -s api/ws-schema.json -d examples/*.json` | — |
| `test` | `flutter test --coverage`; `go test ./... -coverprofile=cover.out`; `go vet ./...` | `coverage.lcov`, `cover.out` |
| `build_backend` | `docker buildx build --platform linux/amd64 -t noctis-backend:${SHA} deploy/`; `docker save` | `noctis-backend-${SHA}.tar` |
| `integration` | `docker compose -f deploy/docker-compose.ci.yml up -d`; запуск интеграционных Go-тестов с тегом `// +build integration` | logs |
| `build_android` | Восстановление `~/.pub-cache` и `~/.gradle/caches` из `actions/cache`; декодирование keystore из `ANDROID_KEYSTORE_BASE64`; `flutter build apk --release` с key-properties; uploadArtifact `noctis-release.apk` | `noctis-release.apk` (retention 30 дней) |
| `release` | Только `if: github.ref == 'refs/heads/main' && success()`; вычисление тега `vYYYYMMDD-<sha7>`; `gh release create` с APK; описание = `git log --pretty='* %s' last_tag..HEAD` | GitHub Release |

### Подпись APK

```yaml
- name: Decode keystore
  run: echo "${{ secrets.ANDROID_KEYSTORE_BASE64 }}" | base64 -d > android/app/release.keystore
- name: Write key.properties
  run: |
    cat > android/key.properties <<EOF
    storeFile=release.keystore
    storePassword=${{ secrets.ANDROID_KEYSTORE_PASSWORD }}
    keyAlias=${{ secrets.ANDROID_KEY_ALIAS }}
    keyPassword=${{ secrets.ANDROID_KEY_PASSWORD }}
    EOF
- name: Build APK
  run: flutter build apk --release
```

`android/app/build.gradle` подключает `key.properties` в `signingConfigs.release`, выбирает `signingConfig signingConfigs.release` для buildType `release`, ProGuard включён.

### Кеширование

- `~/.pub-cache` — ключ `pub-${{ runner.os }}-${{ hashFiles('**/pubspec.lock') }}`.
- `~/.gradle/caches`, `~/.gradle/wrapper` — ключ `gradle-${{ hashFiles('android/**/*.gradle*') }}`.
- `~/go/pkg/mod` — ключ `go-${{ hashFiles('**/go.sum') }}`.

### Тегирование релизов

`tag = "v$(date -u +%Y%m%d)-${GITHUB_SHA::7}"`. Если на тот же день уже есть тег с тем же sha7, добавляется суффикс `-r2`, `-r3` (теоретически, на практике невозможно при rebase-flow).

## VPS Provisioning Design

### `deploy/provision.sh` — структура

Принцип идемпотентности (R58.11): каждое действие проверяет текущее состояние перед изменением (`command -v docker || install_docker`, `ufw status | grep -q "443/tcp" || ufw allow 443`, `dpkg -s nginx >/dev/null 2>&1 || apt install nginx`). Скрипт начинается с `set -euo pipefail` и `trap on_error ERR` (R58.10).

```bash
#!/usr/bin/env bash
set -euo pipefail

DOMAIN="${DOMAIN:-noctis.example}"
EMAIL="${LE_EMAIL:-admin@noctis.example}"
WITH_MONITORING="${WITH_MONITORING:-0}"

require_root            # проверка uid=0 / sudo
update_system           # apt-get update && apt-get -y upgrade
install_docker          # docker-ce + compose plugin (idempotent: docker --version)
install_nginx           # apt install nginx
install_certbot         # certbot + python3-certbot-nginx
configure_ufw           # 22, 80, 443; default deny incoming
configure_fail2ban      # /etc/fail2ban/jail.d/sshd.local
prepare_dirs            # /etc/noctis, /var/lib/noctis/{pg,redis,minio}, /var/backups/noctis
write_env_template      # /etc/noctis/.env (если ещё не существует)
write_compose           # /etc/noctis/docker-compose.yml
write_nginx_conf        # /etc/nginx/sites-available/noctis -> enabled
issue_tls_certificate   # certbot --nginx -d $DOMAIN -m $EMAIL --agree-tos --non-interactive
start_stack             # docker compose -f /etc/noctis/docker-compose.yml up -d
install_backup_cron     # /etc/cron.daily/noctis-backup
[[ "$WITH_MONITORING" == "1" ]] && enable_monitoring
verify_health           # curl -fsS https://$DOMAIN/healthz
echo "OK"
```

Каждая функция возвращает 0 при успехе и не-0 при ошибке; `set -e` обрывает скрипт.

### `docker-compose.yml`

```yaml
services:
  postgres:
    image: postgres:15
    restart: unless-stopped
    environment:
      POSTGRES_DB: noctis
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
    volumes:
      - /var/lib/noctis/pg:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER} -d noctis"]
      interval: 10s
      timeout: 5s
      retries: 5

  redis:
    image: redis:7
    restart: unless-stopped
    command: ["redis-server", "--appendonly", "yes", "--requirepass", "${REDIS_PASSWORD}"]
    volumes:
      - /var/lib/noctis/redis:/data
    healthcheck:
      test: ["CMD", "redis-cli", "-a", "${REDIS_PASSWORD}", "PING"]
      interval: 10s
      timeout: 3s
      retries: 5

  minio:
    image: minio/minio:RELEASE.2024-12-13T22-19-12Z
    restart: unless-stopped
    command: server /data --console-address ":9001"
    environment:
      MINIO_ROOT_USER: ${S3_ACCESS_KEY}
      MINIO_ROOT_PASSWORD: ${S3_SECRET_KEY}
    volumes:
      - /var/lib/noctis/minio:/data
    healthcheck:
      test: ["CMD", "curl", "-fsS", "http://localhost:9000/minio/health/ready"]
      interval: 15s
      timeout: 5s
      retries: 5

  coturn:
    image: coturn/coturn:4.6
    restart: unless-stopped
    network_mode: host
    command: -n -c /etc/coturn/turnserver.conf
    volumes:
      - /etc/noctis/turnserver.conf:/etc/coturn/turnserver.conf:ro

  backend:
    image: ghcr.io/${GH_OWNER}/noctis-backend:${BACKEND_TAG:-latest}
    restart: unless-stopped
    depends_on:
      postgres: { condition: service_healthy }
      redis:    { condition: service_healthy }
      minio:    { condition: service_healthy }
    env_file: /etc/noctis/.env
    healthcheck:
      test: ["CMD", "wget", "-qO-", "http://localhost:8080/healthz"]
      interval: 15s
      timeout: 5s
      retries: 5

  nginx:
    image: nginx:1.27
    restart: unless-stopped
    ports: ["80:80", "443:443"]
    volumes:
      - /etc/nginx/sites-available/noctis:/etc/nginx/conf.d/noctis.conf:ro
      - /etc/letsencrypt:/etc/letsencrypt:ro
    depends_on:
      backend: { condition: service_healthy }
```

### Шаблон `.env`

```env
# --- Postgres ---
POSTGRES_USER=noctis
POSTGRES_PASSWORD=__GENERATE__
DATABASE_URL=postgres://noctis:__GENERATE__@postgres:5432/noctis?sslmode=disable

# --- Redis ---
REDIS_PASSWORD=__GENERATE__
REDIS_URL=redis://:__GENERATE__@redis:6379/0

# --- JWT ---
JWT_SECRET_CURRENT=__GENERATE_64B_BASE64__
JWT_SECRET_PREVIOUS=

# --- S3/MinIO ---
S3_ENDPOINT=http://minio:9000
S3_ACCESS_KEY=__GENERATE__
S3_SECRET_KEY=__GENERATE__
S3_BUCKET=noctis-media

# --- SMS ---
SMS_PROVIDER_API_KEY=
SMS_PROVIDER=mock     # mock|twilio|smsru

# --- SMTP ---
SMTP_URL=smtp://user:pass@smtp.example:587

# --- Push ---
FCM_SERVICE_ACCOUNT_JSON=
APNS_KEY_ID=
APNS_TEAM_ID=
APNS_KEY_P8_BASE64=
APNS_BUNDLE_ID=app.noctis

# --- TURN ---
TURN_REALM=noctis.example
TURN_SECRET=__GENERATE__

# --- App ---
APP_DOMAIN=noctis.example
LOG_LEVEL=info
```

`__GENERATE__` подставляется `provision.sh` через `openssl rand -hex 24`.

### Резервное копирование (R62)

`/etc/cron.daily/noctis-backup`:

```bash
#!/usr/bin/env bash
set -euo pipefail
DATE=$(date -u +%Y%m%d)
docker exec noctis-postgres-1 pg_dump -U "$POSTGRES_USER" -Fc noctis \
  | gzip -9 > "/var/backups/noctis/pg-$DATE.dump.gz"
# хранение: 7 дневных + 4 еженедельных
find /var/backups/noctis -name 'pg-*.dump.gz' -mtime +7 \
  ! -name "pg-$(date -u -d 'last sunday' +%Y%m%d)*" -delete
```

При ошибке — логирование через `logger -p user.err -t noctis-backup`.

## Безопасность

### Транспорт (R53)

- Nginx: `ssl_protocols TLSv1.2 TLSv1.3;`, ECDHE-only ciphers, `ssl_session_tickets off`, OCSP stapling, HSTS `max-age=31536000; includeSubDomains; preload`.
- Сертификат от Let's Encrypt, обновляется `certbot renew` через systemd-таймер, минимум за 14 суток до истечения (R53.2).
- Клиент NOCTIS_App включает базовый pin-набор (root CA Let's Encrypt) и при `BadCertificateException` рвёт соединение (R53.3).

### Криптографические параметры

| Назначение | Алгоритм | Параметры |
| --- | --- | --- |
| Облачный пароль | Argon2id | `time=3, memory=64MiB, parallelism=4, salt=16B, hash=32B` (R4.1) |
| JWT access | HS256 | 64-байтный секрет, ротация двумя ключами |
| Refresh-токен | random | 256 бит, хранится как SHA-256 |
| OTP | random | 6 цифр, секрет = константа `crypto/rand`, в Redis SHA-256 |
| Локальная БД | AES-256 (SQLCipher) | Ключ 32 байта, KeyStore/Keychain + biometric-обёртка |
| Экспорт чата | AES-256-GCM | PBKDF2-HMAC-SHA256, 200 000 итераций |
| Secret_Chat | X3DH + Double Ratchet | libsignal-protocol-dart |
| Звонки | SRTP/DTLS | через WebRTC stack |

### Push-уведомления (R16.6)

- Для Secret_Chat в payload передаётся только `{ "chat_id": ..., "kind": "secret" }`. Тело отображается клиентом из локальной БД после расшифровки.
- При включённой опции «Скрытые превью» (R65.10) тот же режим применяется ко всем чатам.

### Локальная БД и биометрия (R45.4, R46)

- Ключ БД находится в KeyStore (Android) / Keychain (iOS) с флагом «требует биометрии при доступе».
- При 3 неуспешных биопроверках подряд (R46.3) запрашивается PIN; PIN-хеш — Argon2id с теми же параметрами, что и облачный пароль.
- При фоне приложения дольше 60 с — перед показом контента запрашивается биометрия.

### Ротация JWT-ключей

- Cron-job раз в 30 дней генерирует новый `JWT_SECRET_CURRENT`; старый перемещается в `JWT_SECRET_PREVIOUS` ровно на 24 часа, после чего обнуляется.
- `Auth_Service` при валидации перебирает оба секрета.

## Наблюдаемость

### Логирование (R52)

- Логгер: `zerolog` (Go), вывод в stdout; контейнер захватывается Docker logging driver `json-file` с ротацией.
- Поля каждого события: `timestamp`, `level`, `request_id`, `user_id`, `session_id`, `device_id`, `event`, `chat_id?`, `latency_ms?`, `error?`.
- `request_id` генерируется в transport-middleware при отсутствии заголовка `X-Request-ID` и пробрасывается через `context.Context`.
- Уровни логирования управляются `LOG_LEVEL` ENV; по `SIGHUP` уровень перечитывается (R59.3).

### Метрики Prometheus (R47.5, R52.2)

| Имя | Тип | Назначение |
| --- | --- | --- |
| `noctis_ws_connections_active` | gauge | Активные WebSocket-соединения |
| `noctis_http_request_duration_seconds{route,method,status}` | histogram | Латентность HTTP |
| `noctis_ws_message_latency_seconds{type}` | histogram | Латентность доставки WS |
| `noctis_messages_sent_total{kind}` | counter | Отправленные сообщения |
| `noctis_message_send_errors_total{code}` | counter | Ошибки отправки |
| `noctis_outbox_queue_size` | gauge | Размер серверной очереди отложенной доставки |
| `noctis_auth_otp_requests_total{result}` | counter | OTP-запросы |
| `noctis_auth_login_total{result}` | counter | Логины |
| `noctis_rate_limited_total{bucket}` | counter | 429 ответы |
| `noctis_disappearing_deletions_total` | counter | Удалённые TTL-сообщения |
| `noctis_call_setup_duration_seconds` | histogram | Время установления звонка |
| `noctis_pg_pool_in_use`, `noctis_pg_pool_idle` | gauge | Пул PG |
| `noctis_redis_op_duration_seconds{op}` | histogram | Латентность Redis |

### Дашборды Grafana

1. **Overview**: WS-соединения, RPS, p50/p95/p99 латентности, error rate, CPU/RSS бэкенда.
2. **Auth**: OTP-запросы, логины, провалы, 429-rate, размер очереди SMS.
3. **Messaging**: TPS отправок, очередь outbox, латентность WS-fanout, размер `expiring_msg:zset`.
4. **Calls**: число звонков по типам, время setup, отказы.
5. **Infra**: PG IOPS, размер таблиц, Redis memory, MinIO bandwidth, диск VPS, certbot expiry.

Алерты (Alertmanager или Grafana Alerting): `error_rate > 1% за 5m`, `ws_connections_active drop > 50% за 1m`, `pg_replication_lag > 10s`, `cert_expiry < 14 дней`, `disk_free < 15%`.

## Открытые вопросы и решения

| Вопрос | Варианты | Решение |
| --- | --- | --- |
| Хранилище медиа | (a) локальная ФС с раздачей через Nginx; (b) MinIO (S3-совместимый) в Docker; (c) внешний S3 | **MinIO в Docker Compose**. Сохраняет S3-API (`internal/storage/minio` использует `aws-sdk-go-v2`), отделяет данные от приложения, упрощает резервное копирование и будущий вынос на отдельный сервер. Локальная ФС отклонена из-за отсутствия presigned URL и будущих сложностей миграции. |
| SMS-провайдер | Twilio, SMS.ru, Vonage, MessageBird | Введён интерфейс `SmsSender` с реализациями `mock`, `twilio`, `smsru`. Выбор — через `SMS_PROVIDER` ENV. По умолчанию для dev/CI используется `mock` (логирует код в stdout); продовый провайдер выбирается на этапе релиза. |
| TURN-сервер | coturn vs cloud (Twilio NTS) | **coturn в Docker (host network)**. Бесплатно, контролируется на том же VPS. Аутентификация через `lt-cred-mech` с временными credentials, выдаваемыми `Call_Service` (HMAC-SHA1, TTL 3600 с). |
| Полнотекстовый поиск (русский) | PostgreSQL `to_tsvector('russian')` vs внешний индекс | **PostgreSQL FTS** на старте: достаточно для ≤100k сообщений/чат (R9.4). Индекс — комбинированный GIN. При росте >10M сообщений/инстанс предусмотрен переход на Meilisearch/OpenSearch (вынесено в backlog). |
| Транскрибация голоса | Whisper.cpp on-device vs облачный API | **Облачный API** (через `Media_Service`) на старте — быстрее реализовать; клиентская whisper.cpp сборка вынесена в backlog как опция «приватная транскрибация». |
| Масштабирование за 1 инстанс | Sticky LB по user_id vs Redis Pub/Sub | Redis Pub/Sub: каждый инстанс подписывается на `user_chan:{user_id}` для своих активных WS, что позволяет любому инстансу принимать соединение и доставлять сообщения от других инстансов. |
| Управление миграциями | `goose` vs `golang-migrate` | **`goose`**: поддерживает Go-миграции (полезно для backfill), проще CLI. |
