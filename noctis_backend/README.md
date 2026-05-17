# NOCTIS — backend (Go)

Fiber + WebSocket + PostgreSQL + Redis. MVP-функционал для запуска: phone-OTP вход, выпуск JWT, лента сообщений 1:1, real-time доставка через Redis pub/sub.

## Локальный запуск

```bash
cd noctis_backend
go mod tidy
DATABASE_URL=postgres://noctis:noctis@localhost:5432/noctis?sslmode=disable \
REDIS_URL=redis://localhost:6379/0 \
JWT_SECRET=$(openssl rand -hex 32) \
go run ./cmd/noctis
```

`/healthz`, `/api/v1/auth/phone/start|verify|refresh`, `/api/v1/chats/:id/messages`, WS `/ws?token=<access>`.

В режиме `SMS_PROVIDER=mock` (по умолчанию) код подтверждения пишется в логи backend.

## Сборка контейнера

```bash
docker build -t noctis-backend:dev -f Dockerfile .
```

Образ публикуется в `ghcr.io/Sliva2010/apkmes-backend:<sha>` через GitHub Actions (см. `.github/workflows/backend.yml`).
