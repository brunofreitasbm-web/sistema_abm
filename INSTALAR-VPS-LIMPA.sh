#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
echo "Instalação limpa da Passagem de Serviço ABM v3.1.0"
echo "Os dados existentes, se houver, serão preservados e copiados para backup."
exec bash ./install.sh
