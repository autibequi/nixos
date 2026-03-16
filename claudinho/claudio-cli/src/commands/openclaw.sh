mkdir -p "$HOME/.openclaw"
if [[ ! -f "$HOME/.openclaw/openclaw.json" ]]; then
  cp "$claudio_nixos_dir/.openclaw/openclaw.json" "$HOME/.openclaw/openclaw.json" 2>/dev/null || true
  echo "[openclaw] Config copiada para $HOME/.openclaw (LM Studio em host.docker.internal:1234)"
fi
docker compose -f "$claudio_compose_file" up -d sandbox
docker compose -f "$claudio_compose_file" exec -it sandbox openclaw gateway
