zion_load_config
nixos_dir="${ZION_NIXOS_DIR:-${HOST_NIXOS_DIR:-$HOME/nixos}}"
input="${args[input]:-}"

if [[ -n "$input" ]]; then
  exec nix flake update "$input" --flake "$nixos_dir"
else
  exec nix flake update --flake "$nixos_dir"
fi
