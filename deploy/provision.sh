#!/usr/bin/env bash
# NOCTIS — provision VPS (Ubuntu 22.04 LTS).
# Идемпотентный скрипт: безопасно запускать многократно.
#
# Использование:
#   sudo DOMAIN=noctis.example.com LE_EMAIL=admin@noctis.example.com \
#        bash provision.sh
#
# Опции через ENV:
#   DOMAIN            — публичный домен (для TLS); если пуст — пропустим certbot.
#   LE_EMAIL          — email для Let's Encrypt.
#   WITH_MONITORING   — 1, чтобы включить Prometheus + Grafana.

set -euo pipefail

DOMAIN="${DOMAIN:-}"
LE_EMAIL="${LE_EMAIL:-}"
WITH_MONITORING="${WITH_MONITORING:-0}"
NOCTIS_DIR="/etc/noctis"
DATA_DIR="/var/lib/noctis"
BACKUP_DIR="/var/backups/noctis"

log()  { printf "\033[1;37m[NOCTIS]\033[0m %s\n" "$*"; }
warn() { printf "\033[1;33m[WARN]\033[0m %s\n" "$*" >&2; }
err()  { printf "\033[1;31m[ERR ]\033[0m %s\n" "$*" >&2; }

trap 'err "provision.sh failed (line $LINENO)"; exit 1' ERR

require_root() {
  if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
    err "Запустите скрипт через sudo или от root."
    exit 1
  fi
}

update_system() {
  log "Обновление пакетов..."
  apt-get update -y
  DEBIAN_FRONTEND=noninteractive apt-get -y upgrade
  apt-get install -y \
    ca-certificates curl gnupg lsb-release ufw fail2ban cron \
    openssl jq
}

install_docker() {
  if command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
    log "Docker уже установлен — пропускаем."
    return 0
  fi
  log "Установка Docker Engine..."
  install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
    | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  chmod a+r /etc/apt/keyrings/docker.gpg

  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
    > /etc/apt/sources.list.d/docker.list

  apt-get update -y
  apt-get install -y docker-ce docker-ce-cli containerd.io \
    docker-buildx-plugin docker-compose-plugin

  systemctl enable --now docker
}

install_nginx_certbot() {
  if ! command -v nginx >/dev/null 2>&1; then
    log "Установка Nginx..."
    apt-get install -y nginx
  fi
  if ! command -v certbot >/dev/null 2>&1; then
    log "Установка certbot..."
    apt-get install -y certbot python3-certbot-nginx
  fi
}

configure_ufw() {
  log "Настройка UFW..."
  ufw --force reset >/dev/null
  ufw default deny incoming
  ufw default allow outgoing
  ufw allow 22/tcp
  ufw allow 80/tcp
  ufw allow 443/tcp
  ufw --force enable
}

configure_fail2ban() {
  log "Настройка fail2ban..."
  cat >/etc/fail2ban/jail.d/sshd.local <<'EOF'
[sshd]
enabled = true
port    = ssh
maxretry = 5
findtime = 600
bantime  = 3600
EOF
  systemctl enable --now fail2ban
  systemctl reload fail2ban || true
}

prepare_dirs() {
  log "Подготовка директорий..."
  mkdir -p "$NOCTIS_DIR" "$DATA_DIR/pg" "$DATA_DIR/redis" "$DATA_DIR/minio" "$BACKUP_DIR"
  chmod 0750 "$NOCTIS_DIR"
}

write_env() {
  if [[ -f "$NOCTIS_DIR/.env" ]]; then
    log ".env уже существует — оставляем без изменений."
    return 0
  fi
  log "Генерация .env с секретами..."
  local pg_pass redis_pass jwt_secret s3_access s3_secret turn_secret
  pg_pass=$(openssl rand -hex 24)
  redis_pass=$(openssl rand -hex 24)
  jwt_secret=$(openssl rand -hex 48)
  s3_access=$(openssl rand -hex 12)
  s3_secret=$(openssl rand -hex 24)
  turn_secret=$(openssl rand -hex 24)

  cat >"$NOCTIS_DIR/.env" <<EOF
APP_DOMAIN=${DOMAIN:-noctis.local}
LOG_LEVEL=info

POSTGRES_USER=noctis
POSTGRES_PASSWORD=${pg_pass}
POSTGRES_DB=noctis
DATABASE_URL=postgres://noctis:${pg_pass}@postgres:5432/noctis?sslmode=disable

REDIS_PASSWORD=${redis_pass}
REDIS_URL=redis://:${redis_pass}@redis:6379/0

JWT_SECRET_CURRENT=${jwt_secret}
JWT_SECRET_PREVIOUS=

S3_ENDPOINT=http://minio:9000
S3_ACCESS_KEY=${s3_access}
S3_SECRET_KEY=${s3_secret}
S3_BUCKET=noctis-media

SMS_PROVIDER=mock
SMS_PROVIDER_API_KEY=

TURN_REALM=${DOMAIN:-noctis.local}
TURN_SECRET=${turn_secret}
EOF
  chmod 0600 "$NOCTIS_DIR/.env"
}

write_compose() {
  log "Запись docker-compose.yml..."
  cat >"$NOCTIS_DIR/docker-compose.yml" <<'YAML'
services:
  postgres:
    image: postgres:15
    restart: unless-stopped
    env_file: .env
    volumes:
      - /var/lib/noctis/pg:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U $$POSTGRES_USER -d $$POSTGRES_DB"]
      interval: 10s
      timeout: 5s
      retries: 10

  redis:
    image: redis:7-alpine
    restart: unless-stopped
    env_file: .env
    command: ["sh", "-c", "redis-server --appendonly yes --requirepass $$REDIS_PASSWORD"]
    volumes:
      - /var/lib/noctis/redis:/data
    healthcheck:
      test: ["CMD-SHELL", "redis-cli -a $$REDIS_PASSWORD PING | grep -q PONG"]
      interval: 10s
      timeout: 3s
      retries: 10

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
      retries: 10
YAML
}

write_nginx() {
  log "Запись Nginx-конфига..."
  cat >/etc/nginx/sites-available/noctis <<EOF
server {
    listen 80;
    server_name ${DOMAIN:-_};

    location / {
        return 200 'NOCTIS backend placeholder. Deploy backend container to enable API.';
        add_header Content-Type text/plain;
    }
}
EOF
  ln -sf /etc/nginx/sites-available/noctis /etc/nginx/sites-enabled/noctis
  rm -f /etc/nginx/sites-enabled/default
  nginx -t
  systemctl reload nginx || systemctl restart nginx
}

issue_tls() {
  if [[ -z "$DOMAIN" || -z "$LE_EMAIL" ]]; then
    warn "DOMAIN или LE_EMAIL не заданы — пропускаем выпуск TLS."
    return 0
  fi
  if [[ -d "/etc/letsencrypt/live/$DOMAIN" ]]; then
    log "TLS-сертификат для $DOMAIN уже существует — пропускаем."
    return 0
  fi
  log "Выпуск TLS-сертификата для $DOMAIN..."
  certbot --nginx -d "$DOMAIN" -m "$LE_EMAIL" --agree-tos --non-interactive --redirect
}

start_stack() {
  log "Запуск Docker Compose стека (postgres + redis + minio)..."
  (cd "$NOCTIS_DIR" && docker compose up -d)
}

install_backup_cron() {
  log "Установка cron-бэкапа PostgreSQL..."
  cat >/etc/cron.daily/noctis-backup <<'BASH'
#!/usr/bin/env bash
set -euo pipefail
DATE=$(date -u +%Y%m%d)
mkdir -p /var/backups/noctis
docker exec $(docker ps -qf 'name=postgres') \
  pg_dumpall -U "$(grep POSTGRES_USER /etc/noctis/.env | cut -d= -f2)" \
  | gzip -9 > "/var/backups/noctis/pg-${DATE}.sql.gz"
find /var/backups/noctis -name 'pg-*.sql.gz' -mtime +14 -delete
BASH
  chmod +x /etc/cron.daily/noctis-backup
}

main() {
  require_root
  log "NOCTIS provision начат на $(hostname) ($(date -u +%FT%TZ))"
  update_system
  install_docker
  install_nginx_certbot
  configure_ufw
  configure_fail2ban
  prepare_dirs
  write_env
  write_compose
  write_nginx
  issue_tls
  start_stack
  install_backup_cron
  log "✓ Готово. Конфиги: $NOCTIS_DIR | данные: $DATA_DIR | бэкапы: $BACKUP_DIR"
  log "Дальше: соберите/опубликуйте образ noctis-backend и добавьте сервис в $NOCTIS_DIR/docker-compose.yml."
}

main "$@"
