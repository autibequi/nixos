#!/usr/bin/env bash
# Setup the Python venv for whisper-ptt
# Run once after nixos-rebuild switch

set -euo pipefail

VENV="$HOME/.venv/whisper"

echo "Creating venv at $VENV..."
python3 -m venv "$VENV"

echo "Installing dependencies..."
"$VENV/bin/pip" install --upgrade pip
"$VENV/bin/pip" install \
    faster-whisper \
    sounddevice \
    webrtcvad-wheels \
    numpy

echo ""
echo "Done! Enable the service with:"
echo "  systemctl --user enable --now whisper-ptt"
