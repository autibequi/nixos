leech_load_config
nixos_dir="${LEECH_NIXOS_DIR:-${HOST_NIXOS_DIR:-$HOME/nixos}}"
exec nh os switch "$nixos_dir"
