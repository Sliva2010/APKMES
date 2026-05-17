# NOCTIS — развёртывание на VPS

## Требования
- VPS Ubuntu 22.04 LTS
- IP: 79.137.162.27 (или ваш собственный)
- Доменное имя, направленное A-записью на IP (для TLS)
- Доступ root или sudo

## Быстрый старт

1. Скопируйте `provision.sh` на сервер:
   ```bash
   scp deploy/provision.sh root@79.137.162.27:/root/
   ```

2. Запустите провижн на сервере:
   ```bash
   ssh root@79.137.162.27
   sudo DOMAIN=your-domain.com LE_EMAIL=you@your-domain.com bash /root/provision.sh
   ```

3. Скрипт идемпотентен — можно перезапускать столько раз, сколько нужно.

## Что делает скрипт
- Обновляет систему и ставит зависимости (curl, ufw, fail2ban, cron, openssl, jq).
- Устанавливает Docker Engine + Docker Compose plugin.
- Устанавливает Nginx и certbot.
- Настраивает UFW (только 22, 80, 443 входящие) и fail2ban.
- Создаёт `/etc/noctis/.env` с автогенерируемыми секретами.
- Запускает PostgreSQL 15, Redis 7, MinIO через Docker Compose.
- Если задан DOMAIN+LE_EMAIL — выпускает TLS-сертификат Let's Encrypt.
- Ставит ежедневный cron-бэкап PostgreSQL в `/var/backups/noctis/`.

## После провижна
Бэкенд NOCTIS — отдельный шаг (Go-приложение собирается из `noctis_backend/`). Когда будет готов образ, добавьте его в `/etc/noctis/docker-compose.yml` и сделайте `docker compose up -d`.

## Полезные команды
```bash
# Статус контейнеров
cd /etc/noctis && docker compose ps

# Логи
docker compose logs -f --tail=100

# Перезапуск
docker compose restart

# Бэкапы
ls -la /var/backups/noctis/
```
