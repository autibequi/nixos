# Executa uma task com o agente Puppy (genérico ou específico via --agent).
zion_load_config

PUPPY_PROJECT="${PUPPY_PROJECT:-puppy-workers}"
PUPPY_COMPOSE="$zion_cli_dir/docker-compose.puppy.yml"

task_name="${args[task]}"
agent_name="${args[--agent]:-puppy}"
model="${args[--model]:-haiku}"
timeout_secs="${args[--timeout]:-300}"
headless="${args[--headless]}"
max_turns="${args[--max-turns]:-12}"

# Lista tasks disponíveis
if [[ "$task_name" == "list" ]]; then
  doing_dir="$zion_obsidian_path/tasks/doing"
  if [[ -d "$doing_dir" ]]; then
    echo "Tasks em doing:"
    ls "$doing_dir"
  else
    echo "Nenhuma task em doing ($doing_dir)" >&2
  fi
  exit 0
fi

# Check container is running
if ! OBSIDIAN_PATH="$zion_obsidian_path" docker compose -f "$PUPPY_COMPOSE" -p "$PUPPY_PROJECT" ps --status running 2>/dev/null | grep -q puppy; then
  echo "[zion puppy] Container puppy não está rodando. Use: zion puppy start" >&2
  exit 1
fi

# Resolve agent file path inside the container
agent_file="/workspace/zion/agents/${agent_name}/agent.md"

echo "[zion puppy] Rodando task '$task_name' com agente '$agent_name'..."

# Build env flags
env_flags=()
env_flags+=(-e "TASK_NAME=$task_name")
env_flags+=(-e "AGENT_NAME=$agent_name")
env_flags+=(-e "HEADLESS=${headless:+1}")
env_flags+=(-e "PUPPY_TIMEOUT=$timeout_secs")

# Build prompt
if [[ -n "$headless" ]]; then
  deadline_str="$(date -u -d "+${timeout_secs} seconds" +%H:%M:%S 2>/dev/null || echo "${timeout_secs}s from now")"
  prompt="[HEADLESS MODE] Timeout: ${timeout_secs}s | Deadline: ${deadline_str} --- Execute a task: $task_name"
else
  prompt="Execute a task: $task_name"
fi

OBSIDIAN_PATH="$zion_obsidian_path" \
  docker compose -f "$PUPPY_COMPOSE" -p "$PUPPY_PROJECT" \
  exec -u claude "${env_flags[@]}" puppy \
  bash -c "
    if [ -f '$agent_file' ]; then
      agent_prompt=\"\$(cat '$agent_file')\"
      timeout '$timeout_secs' claude \
        --permission-mode acceptEdits \
        --model '$model' \
        --max-turns '$max_turns' \
        --append-system-prompt \"\$agent_prompt\" \
        -p '$prompt'
    else
      echo '[puppy_task] Agent file not found: $agent_file' >&2
      exit 1
    fi
  "
