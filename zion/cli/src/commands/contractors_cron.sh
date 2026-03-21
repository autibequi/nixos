# Lê clock: dos agent.md e atualiza zion-contractors.nix
zion_load_config

ZION_DIR="${ZION_NIXOS_DIR:-$HOME/nixos}/zion"
NIX_FILE="${ZION_NIXOS_DIR:-$HOME/nixos}/modules/zion-contractors.nix"
AGENTS_DIR="$ZION_DIR/agents"

# Fallbacks
for try in /workspace/mnt/zion /workspace/nixos/zion; do
  [ -d "$try" ] && AGENTS_DIR="$try/agents" && break
done
for try in /workspace/mnt/modules/zion-contractors.nix /workspace/nixos/modules/zion-contractors.nix; do
  [ -f "$try" ] && NIX_FILE="$try" && break
done

if [ ! -d "$AGENTS_DIR" ]; then
  echo "agents dir nao encontrado"
  exit 1
fi
if [ ! -f "$NIX_FILE" ]; then
  echo "zion-contractors.nix nao encontrado"
  exit 1
fi

# Parsear clock: everyN de cada agent.md
# clock: every10 -> 10min; onBootSec escalonado por indice
declare -a SCHEDULED
IDX=0

while IFS= read -r agent_dir; do
  name=$(basename "$agent_dir")
  agent_md="$agent_dir/agent.md"
  [ -f "$agent_md" ] || continue

  clock=$(awk '/^---/{fm++} fm==1 && /^clock:/{print $2}' "$agent_md")
  [ -z "$clock" ] && continue

  minutes="${clock#every}"
  if ! [[ "$minutes" =~ ^[0-9]+$ ]]; then
    echo "[skip] $name: clock='$clock' formato invalido"
    continue
  fi

  IDX=$((IDX + 1))
  boot_min=$((IDX + 2))
  SCHEDULED+=("$name $boot_min $minutes")
  echo "[cron] $name  boot=${boot_min}min  interval=${minutes}min"
done < <(find "$AGENTS_DIR" -maxdepth 1 -mindepth 1 -type d | sort)

if [ ${#SCHEDULED[@]} -eq 0 ]; then
  echo "Nenhum contractor com campo clock: encontrado."
  exit 0
fi

# Gerar bloco scheduled para o .nix
BLOCK="  # Contractors com timer automatico: { name, onBootSec, onActiveSec }"$'\n'
BLOCK+="  # Gerado por \`zion contractors cron\` -- edite clock: nos agent.md e rode o comando"$'\n'
BLOCK+="  scheduled = ["$'\n'
for entry in "${SCHEDULED[@]}"; do
  read -r name boot_min minutes <<< "$entry"
  BLOCK+=$(printf '    { name = "%s"; onBootSec = "%dmin";  onActiveSec = "%dmin"; }\n' "$name" "$boot_min" "$minutes")
done
BLOCK+="  ];"

# Substituir bloco scheduled no .nix
TMPFILE=$(mktemp)
awk -v block="$BLOCK" '
  /^  # Contractors com timer/ { in_block=1 }
  in_block && /^  \];/ {
    print block
    in_block=0
    next
  }
  !in_block { print }
' "$NIX_FILE" > "$TMPFILE"

if ! diff -q "$NIX_FILE" "$TMPFILE" > /dev/null 2>&1; then
  cp "$TMPFILE" "$NIX_FILE"
  echo ""
  echo "zion-contractors.nix atualizado."
  echo "Rode: zion switch"
else
  echo ""
  echo "Nenhuma mudanca necessaria."
fi
rm -f "$TMPFILE"
