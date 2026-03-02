#!/usr/bin/env bash
# Gera cert e chave autoassinados para o reverse proxy (localhost).
# Rodar uma vez: ./gen-cert.sh (ou bash gen-cert.sh)

openssl req -x509 -nodes -days 825 -newkey rsa:2048 -keyout certs/privkey.pem -out certs/fullchain.pem -subj "/CN=localhost/O=Local/C=BR" -addext "subjectAltName=DNS:localhost,DNS:*.localhost,IP:127.0.0.1,IP:::1"
