#!/bin/bash
# gen-cert.sh — Gera certificados TLS locais via mkcert para o dev stack Estratégia.
#
# Adaptado do original em plug/containers/services/reverseproxy/gen-cert.sh.
# Diferença: CERT_DIR aponta para ./certs/ local (relativo a este script),
# configurável via variável de ambiente CERT_DIR.
#
# Requer:
#   - mkcert instalado (https://github.com/FiloSottile/mkcert)
#   - nss / libnss3-tools (para certutil, se quiser injetar no Chrome/Firefox)
#
# Instalar mkcert:
#   Linux (Debian/Ubuntu): sudo apt install mkcert
#   macOS: brew install mkcert
#   NixOS / devbox: pkgs.mkcert
#
# Uso:
#   cd /path/to/este/docker-compose/
#   bash scripts/gen-cert.sh
#
# Saída em ${CERT_DIR}:
#   fullchain.pem — certificado (montado em /etc/nginx/certs/)
#   privkey.pem   — chave privada

set -euo pipefail

DOMAIN="local.estrategia-sandbox.com.br"

# CERT_DIR: padrão = ./certs/ relativo ao diretório deste script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPOSE_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
CERT_DIR="${CERT_DIR:-${COMPOSE_DIR}/certs}"

mkdir -p "$CERT_DIR"

echo "gen-cert: instalando CA local (mkcert -install)..."
JAVA_HOME="" mkcert -install || true

echo "gen-cert: gerando certificados em ${CERT_DIR}..."
mkcert \
    -key-file  "${CERT_DIR}/privkey.pem" \
    -cert-file "${CERT_DIR}/fullchain.pem" \
    "$DOMAIN" "*.$DOMAIN" localhost 127.0.0.1

echo "gen-cert: certificados gerados:"
ls -lh "${CERT_DIR}/"

# Injeta CA no NSS do Chrome/Firefox (opcional — pula silenciosamente se certutil ausente)
command -v certutil &>/dev/null || { echo "gen-cert: certutil não encontrado — skip injeção NSS (Chrome/Firefox)"; exit 0; }

CA="$HOME/.local/share/mkcert/rootCA.pem"
NSS="$HOME/.pki/nssdb"

echo "gen-cert: injetando CA no NSS (${NSS})..."
rm -rf "$NSS"
mkdir -p "$NSS"
certutil -d "sql:$NSS" -N --empty-password
certutil -d "sql:$NSS" -A -t "C,," -n "mkcert-estrategia" -i "$CA"
echo "gen-cert: CA injetada no NSS — Chrome/Firefox vão confiar no certificado local."
