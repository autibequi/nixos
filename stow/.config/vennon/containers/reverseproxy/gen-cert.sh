#!/bin/bash
# Generate self-signed certs for local development
# Usage: ./gen-cert.sh

CERT_DIR="$(dirname "$0")/certs"
mkdir -p "$CERT_DIR"

DOMAIN="local.estrategia-sandbox.com.br"
SUBDOMAINS="*.local.estrategia-sandbox.com.br"

openssl req -x509 -nodes -days 365 \
    -newkey rsa:2048 \
    -keyout "$CERT_DIR/privkey.pem" \
    -out "$CERT_DIR/fullchain.pem" \
    -subj "/CN=$DOMAIN" \
    -addext "subjectAltName=DNS:$DOMAIN,DNS:$SUBDOMAINS,DNS:localhost"

echo "Certs generated in $CERT_DIR"
echo "  fullchain.pem"
echo "  privkey.pem"
