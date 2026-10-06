#!/usr/bin/env bash
set -u
PORT="${PORT:-3007}"
BASE="http://127.0.0.1:${PORT}"
echo "== Passagem de Serviço ABM v3.1.0 =="
echo "[1] Serviço systemd"
systemctl --no-pager --full status passagem-servico 2>/dev/null | sed -n '1,12p' || true
echo
echo "[2] Porta"
ss -lntp 2>/dev/null | grep -E ":${PORT}\b" || echo "ERRO: porta ${PORT} não encontrada"
echo
echo "[3] Health"
curl -fsS "$BASE/health" || echo "ERRO: /health indisponível"
echo
echo "[4] Interface administrativa"
code="$(curl -sS -o /tmp/ps-admin.html -w '%{http_code}' "$BASE/admin/" || true)"
echo "HTTP $code"; grep -q 'app.js?v=3.1.0' /tmp/ps-admin.html 2>/dev/null && echo "Admin v3.1.0 OK" || echo "AVISO: HTML do admin não parece ser v3.1.0"
echo
echo "[5] Portal operacional"
code="$(curl -sS -o /tmp/ps-app.html -w '%{http_code}' "$BASE/app/" || true)"
echo "HTTP $code"; grep -q 'app.js?v=3.1.0' /tmp/ps-app.html 2>/dev/null && echo "Portal v3.1.0 OK" || echo "AVISO: HTML do portal não parece ser v3.1.0"
echo
echo "[6] Cache dos assets"
curl -sSI "$BASE/admin/app.js" 2>/dev/null | grep -Ei 'cache-control|pragma' || true
echo
echo "Se houver erro, rode: journalctl -u passagem-servico -n 120 --no-pager"
