period=""
[[ -n "${flag_7d:-}" ]] && period="7d"
[[ -n "${flag_30d:-}" ]] && period="30d"
"$zion_nixos_scripts/api-usage.sh" $period
