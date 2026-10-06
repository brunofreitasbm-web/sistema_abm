#!/usr/bin/env bash
set -euo pipefail
OUT="${1:-/root/passagem-servico-backup-$(date +%Y%m%d-%H%M%S).tar.gz}"
tar -czf "$OUT" /var/lib/passagem-servico /etc/passagem-servico.env 2>/dev/null
echo "$OUT"
