#!/usr/bin/env bash
set -euo pipefail

[ "$(id -u)" -eq 0 ] || { echo "ERRO: execute como root: sudo bash install.sh"; exit 1; }
SRC="$(cd "$(dirname "$0")" && pwd)"
APP_DIR="/opt/passagem-servico"
DATA_DIR="/var/lib/passagem-servico"
PORT="${PORT:-3007}"
DOMAIN="${DOMAIN:-}"
ADMIN_USER="${ADMIN_USER:-admin}"
ADMIN_PASS="${ADMIN_PASS:-}"
ENABLE_SSL="${ENABLE_SSL:-0}"
EMAIL="${EMAIL:-}"

if [ -z "$ADMIN_PASS" ]; then ADMIN_PASS="$(openssl rand -base64 24 2>/dev/null | tr -d '=+/\n' | cut -c1-18 || true)"; fi
[ -n "$ADMIN_PASS" ] || ADMIN_PASS="Pass-$(date +%s)"
SECRET="$(openssl rand -hex 32 2>/dev/null || od -An -N32 -tx1 /dev/urandom | tr -d ' \n')"

apt-get update -y
apt-get install -y nginx ca-certificates curl openssl unzip

mkdir -p "$APP_DIR/web" "$DATA_DIR/uploads" /root/passagem-servico-backups
rm -rf "$APP_DIR/web/admin" "$APP_DIR/web/app"
mkdir -p "$APP_DIR/web/admin" "$APP_DIR/web/app"
if [ -f "$DATA_DIR/db.json" ]; then cp -a "$DATA_DIR/db.json" "/root/passagem-servico-backups/db-$(date +%Y%m%d-%H%M%S).json"; fi

ARCH="$(uname -m)"
case "$ARCH" in
  x86_64|amd64) BIN_SRC="$SRC/passagem-servico-amd64" ;;
  aarch64|arm64) BIN_SRC="$SRC/passagem-servico-arm64" ;;
  *) BIN_SRC="$SRC/passagem-servico" ;;
esac
[ -f "$BIN_SRC" ] || { echo "ERRO: binário não encontrado para $ARCH"; exit 1; }

systemctl stop passagem-servico 2>/dev/null || true
cp -f "$BIN_SRC" "$APP_DIR/passagem-servico"
cp -a "$SRC/web/admin/." "$APP_DIR/web/admin/"
cp -a "$SRC/web/app/." "$APP_DIR/web/app/"
cp -f "$SRC/backup.sh" "$APP_DIR/backup.sh" 2>/dev/null || true
chmod 0755 "$APP_DIR/passagem-servico" "$APP_DIR/backup.sh" 2>/dev/null || true
chown -R root:root "$APP_DIR"
chown -R www-data:www-data "$DATA_DIR"
chmod 0750 "$DATA_DIR" "$DATA_DIR/uploads"

if [ -n "$DOMAIN" ]; then LISTEN_ADDR="127.0.0.1:$PORT"; else LISTEN_ADDR=":$PORT"; fi
cat > /etc/passagem-servico.env <<ENV
LISTEN_ADDR=$LISTEN_ADDR
PORT=$PORT
ALT_PORT=
LISTEN_ADDR_ALT=
DATA_FILE=$DATA_DIR/db.json
UPLOAD_DIR=$DATA_DIR/uploads
APP_SECRET=$SECRET
ADMIN_USER=$ADMIN_USER
ADMIN_PASS=$ADMIN_PASS
MAX_UPLOAD_MB=85
ENV
chmod 0600 /etc/passagem-servico.env

cat > /etc/systemd/system/passagem-servico.service <<'UNIT'
[Unit]
Description=Passagem de Servico ABM v3.1
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=www-data
Group=www-data
WorkingDirectory=/opt/passagem-servico
EnvironmentFile=/etc/passagem-servico.env
ExecStart=/opt/passagem-servico/passagem-servico
Restart=always
RestartSec=2
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=full
ProtectHome=true
ReadWritePaths=/var/lib/passagem-servico

[Install]
WantedBy=multi-user.target
UNIT

systemctl daemon-reload
systemctl enable passagem-servico >/dev/null
systemctl restart passagem-servico
sleep 2

if command -v ufw >/dev/null 2>&1 && ufw status 2>/dev/null | grep -q "Status: active"; then ufw allow "$PORT/tcp" >/dev/null || true; fi

if [ -n "$DOMAIN" ]; then
cat > /etc/nginx/sites-available/passagem-servico <<NGINX
server {
    listen 80;
    listen [::]:80;
    server_name $DOMAIN;
    client_max_body_size 90m;
    location / {
        proxy_pass http://127.0.0.1:$PORT;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_read_timeout 120s;
    }
}
NGINX
ln -sf /etc/nginx/sites-available/passagem-servico /etc/nginx/sites-enabled/passagem-servico
rm -f /etc/nginx/sites-enabled/default
nginx -t && systemctl reload nginx
fi

if [ -n "$DOMAIN" ] && [ "$ENABLE_SSL" = "1" ]; then
  apt-get install -y certbot python3-certbot-nginx
  if [ -n "$EMAIL" ]; then certbot --nginx -d "$DOMAIN" --non-interactive --agree-tos -m "$EMAIL" --redirect || true; else certbot --nginx -d "$DOMAIN" --non-interactive --agree-tos --register-unsafely-without-email --redirect || true; fi
fi

IP="$(hostname -I 2>/dev/null | awk '{print $1}')"
if [ -n "$DOMAIN" ]; then BASE="http://$DOMAIN"; [ -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ] && BASE="https://$DOMAIN"; else BASE="http://${IP:-SEU_IP}:$PORT"; fi

cat > /root/passagem-servico-credenciais.txt <<CREDS
PASSAGEM DE SERVICO ABM v3.1.0
Painel: $BASE/admin/
Aplicativo web: $BASE/app/
Usuario administrador: $ADMIN_USER
Senha inicial: $ADMIN_PASS
Porta: $PORT
CREDS
chmod 0600 /root/passagem-servico-credenciais.txt

curl -fsS "http://127.0.0.1:$PORT/health" >/dev/null || { echo "ERRO: serviço não respondeu. Veja: journalctl -u passagem-servico -n 100 --no-pager"; exit 1; }
echo "============================================================"
echo " PASSAGEM DE SERVICO ABM v3.1.0 INSTALADO"
echo " Painel: $BASE/admin/"
echo " App:    $BASE/app/"
echo " Porta:  $PORT"
echo " Usuario: $ADMIN_USER"
echo " Senha:   $ADMIN_PASS"
echo "============================================================"
