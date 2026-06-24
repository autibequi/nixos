# update — recompila e reinstala o coruja a partir do diretório do projeto.
# coruja_dir() resolve o caminho mesmo que o binário esteja em ~/.local/bin.

dir="$(coruja_dir)"

if [[ ! -f "$dir/Makefile" ]]; then
  echo "erro: Makefile não encontrado em '$dir'." >&2
  echo "      defina CORUJA_DIR apontando para o projeto." >&2
  exit 1
fi

echo "recompilando coruja em $dir ..."
( cd "$dir" && make install )
