zion_load_config
mkdir -p "$HOME/.openclaw"
if [[ ! -f "$HOME/.openclaw/openclaw.json" ]]; then
  cp "$zion_nixos_dir/.openclaw/openclaw.json" "$HOME/.openclaw/openclaw.json" 2>/dev/null || true
  echo "[openclaw] Config copiada para $HOME/.openclaw (LM Studio em host.docker.internal:1234)"
fi
zion_compose_cmd up -d leech
zion_compose_cmd exec -it leech openclaw gateway
