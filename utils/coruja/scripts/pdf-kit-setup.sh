#!/usr/bin/env bash
# pdf-kit-setup.sh — prepara o pdf-kit local pro dev-stack.
#
# Roda no HOST (precisa de acesso ao repo privado estrategiahq/pdf-kit + mkcert).
# Depois de rodar, suba o consumer com:
#   podman compose -f docker-compose.yml -f docker-compose.pdfkit.yaml up -d --build pdf-kit
#
# Ver docs/pdf-kit-local.md para o fluxo completo.

set -euo pipefail

# Clone vive fora do dev-stack, em APP_DIR_PDFKIT (.env) — alinhado aos outros apps.
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PDFKIT_DIR="$(grep -E '^APP_DIR_PDFKIT=' "$ROOT/.env" 2>/dev/null | head -1 | cut -d= -f2-)"
PDFKIT_DIR="${PDFKIT_DIR/#\~/$HOME}"
PDFKIT_DIR="${PDFKIT_DIR:-$HOME/projects/estrategia/pdf-kit}"

# 1. Clona/atualiza o repo do pdf-kit
if [ -d "$PDFKIT_DIR/.git" ]; then
  echo "→ atualizando $PDFKIT_DIR"
  git -C "$PDFKIT_DIR" pull --ff-only
else
  echo "→ clonando estrategiahq/pdf-kit em $PDFKIT_DIR"
  git clone git@github.com:estrategiahq/pdf-kit.git "$PDFKIT_DIR"
fi

# 2. Descobre o CAROOT do mkcert (o Chromium do pdf-kit precisa confiar no cert local)
if command -v mkcert >/dev/null 2>&1; then
  CAROOT="$(mkcert -CAROOT)"
  echo "→ mkcert CAROOT: $CAROOT"
  echo "  exporte antes de subir o compose:  export MKCERT_CAROOT=\"$CAROOT\""
else
  echo "! mkcert não encontrado. Instale e rode 'devbox run trustcert' (ver README do coruja)."
  echo "  Depois: export MKCERT_CAROOT=\"\$(mkcert -CAROOT)\""
fi

echo ""
echo "✓ pronto. Próximo passo:"
echo "  export MKCERT_CAROOT=\"\$(mkcert -CAROOT)\""
echo "  podman compose -f docker-compose.yml -f docker-compose.pdfkit.yaml up -d --build pdf-kit"
