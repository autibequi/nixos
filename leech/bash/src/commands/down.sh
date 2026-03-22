# Para todos os containers leech (sessions compartilhadas + puppy)
leech_load_config

# Shared leech containers: cada projeto sobe com -p <slug> e fica persistente.
# docker stop para todos os containers de imagem leech rodando.
leech_ids=$(docker ps -q --filter "ancestor=leech" 2>/dev/null)
if [[ -n "$leech_ids" ]]; then
  echo "Stopping shared leech containers..."
  # shellcheck disable=SC2086
  docker stop $leech_ids 2>/dev/null || true
fi

echo "Done."
