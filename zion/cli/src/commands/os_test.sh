zion_load_config
nixos_dir="${ZION_NIXOS_DIR:-${HOST_NIXOS_DIR:-$HOME/nixos}}"
exec nh os test "$nixos_dir"
