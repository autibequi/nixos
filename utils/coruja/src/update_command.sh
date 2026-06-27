# update — recompila e reinstala o coruja, no espírito do `yaa update`:
# quiet-on-success (esconde o ruído do build), log capturado, dump SÓ em falha.
# coruja_dir() resolve mesmo com o binário em ~/.local/bin.

dir="$(coruja_dir)"

if [[ ! -f "$dir/Makefile" ]]; then
  echo "erro: Makefile não encontrado em '$dir'." >&2
  echo "      defina CORUJA_DIR apontando para o projeto." >&2
  exit 1
fi

log="/tmp/coruja-update.log"
printf "atualizando coruja em %s " "$dir"

( cd "$dir" && make install ) >"$log" 2>&1 &
pid=$!
while kill -0 "$pid" 2>/dev/null; do printf '.'; sleep 0.5; done

if wait "$pid"; then
  printf ' ✓\n'
  echo "coruja atualizado."
  rm -f "$log"
else
  printf ' ✗\n'
  echo "*** falha no build — log ($log): ***" >&2
  cat "$log" >&2
  exit 1
fi
