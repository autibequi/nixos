# Envia um prompt ao Claude dentro do container puppy.
# Com --headless: informa o agente que ninguem esta observando e deve ir o mais longe possivel.
zion_load_config

PUPPY_PROJECT="${PUPPY_PROJECT:-puppy-workers}"
PUPPY_COMPOSE="$zion_cli_dir/docker-compose.puppy.yml"
prompt="${args[prompt]}"
headless="${args[--headless]}"
timeout_secs="${args[--timeout]:-300}"
model="${args[--model]:-haiku}"

# Build env vars to pass into the container
env_flags=()
env_flags+=(-e "HEADLESS=${headless:+1}")
env_flags+=(-e "PUPPY_TIMEOUT=$timeout_secs")

# Build the final prompt with headless context
final_prompt="$prompt"

if [[ -n "$headless" ]]; then
  deadline_str="$(date -u -d "+${timeout_secs} seconds" +%H:%M:%S 2>/dev/null || echo "${timeout_secs}s from now")"
  headless_header="[HEADLESS MODE] Timeout: ${timeout_secs}s | Deadline: ${deadline_str}"
  headless_rules="REGRAS HEADLESS: Ninguem esta observando. Nao espere input. Va o mais longe que puder. Voce tem ${timeout_secs}s. Reserve os ultimos 30s para salvar estado. Se o tempo acabar sem salvar, VOCE PERDE TODO O PROGRESSO. Priorize: executar > salvar estado > comunicar resultados."
  final_prompt="${headless_header} ${headless_rules} --- ${prompt}"
fi

OBSIDIAN_PATH="$zion_obsidian_path" \
  docker compose -f "$PUPPY_COMPOSE" -p "$PUPPY_PROJECT" \
  exec "${env_flags[@]}" puppy \
  timeout "$timeout_secs" claude \
    --permission-mode bypassPermissions \
    --model "$model" \
    -p "$final_prompt"
