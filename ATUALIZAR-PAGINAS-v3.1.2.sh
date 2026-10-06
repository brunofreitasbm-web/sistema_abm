#!/usr/bin/env bash
set -euo pipefail
[ "$(id -u)" -eq 0 ] || { echo "Execute como root: sudo bash ATUALIZAR-V3.1-INTERFACE.sh"; exit 1; }
SRC="$(cd "$(dirname "$0")" && pwd)"
APP_DIR=/opt/passagem-servico
DATA_DIR=/var/lib/passagem-servico
mkdir -p /root/passagem-servico-backups
if [ -f "$DATA_DIR/db.json" ]; then cp -a "$DATA_DIR/db.json" "/root/passagem-servico-backups/db-$(date +%Y%m%d-%H%M%S).json"; fi
ARCH="$(uname -m)"
case "$ARCH" in x86_64|amd64) BIN="$SRC/passagem-servico-amd64";; aarch64|arm64) BIN="$SRC/passagem-servico-arm64";; *) BIN="$SRC/passagem-servico";; esac
systemctl stop passagem-servico 2>/dev/null || true
mkdir -p "$APP_DIR/web"
rm -rf "$APP_DIR/web/admin" "$APP_DIR/web/app"
mkdir -p "$APP_DIR/web/admin" "$APP_DIR/web/app"
cp -f "$BIN" "$APP_DIR/passagem-servico"
cp -a "$SRC/web/admin/." "$APP_DIR/web/admin/"
cp -a "$SRC/web/app/." "$APP_DIR/web/app/"
chmod 0755 "$APP_DIR/passagem-servico"
chown -R root:root "$APP_DIR"
systemctl daemon-reload
systemctl restart passagem-servico
sleep 2
PORT="$(sed -n 's/^PORT=//p' /etc/passagem-servico.env 2>/dev/null | tail -1)"; PORT="${PORT:-3007}"
curl -fsS "http://127.0.0.1:${PORT}/health" || { echo; echo "Falha após atualização. Veja: journalctl -u passagem-servico -n 100 --no-pager"; exit 1; }
echo
echo "Atualização v3.1.0 concluída. Dados preservados."
