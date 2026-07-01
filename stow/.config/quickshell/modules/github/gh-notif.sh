#!/usr/bin/env bash
# gh-notif.sh — notificações do GitHub pro GithubWidget.
#   poll  → emite JSON da lista E dispara notify-send (toast) pra cada notificação NOVA
#   list  → só emite o JSON (sem toast)
# "Nova" = id ainda não visto em $SEEN. Roda no host (gh + notify-send do sistema).
set -u
PATH="/run/current-system/sw/bin:${HOME}/.nix-profile/bin:/usr/bin:/bin:${PATH:-}"
SEEN="/tmp/gh-notif-seen"

# api.github.com/repos/O/R/pulls/N  →  github.com/O/R/pull/N (abrível no browser)
web_url() {
  printf '%s' "$1" \
    | sed -e 's#api\.github\.com/repos#github.com#' \
          -e 's#/pulls/#/pull/#' -e 's#/issues/#/issues/#'
}

fetch() {
  gh api notifications --jq '[.[] | {
    id, reason,
    title: .subject.title,
    type:  .subject.type,
    repo:  .repository.full_name,
    api:   (.subject.url // "")
  }]' 2>/dev/null || echo '[]'
}

json="$(fetch)"

if [ "${1:-poll}" = "poll" ]; then
  if [ ! -f "$SEEN" ]; then
    # 1ª execução: baseline silencioso (marca tudo como visto, SEM 50 toasts de uma vez)
    printf '%s' "$json" | jq -r '.[].id' > "$SEEN"
  else
    printf '%s' "$json" | jq -r '.[] | "\(.id)\t\(.repo)\t\(.title)"' | while IFS=$'\t' read -r id repo title; do
      grep -qxF "$id" "$SEEN" 2>/dev/null && continue
      # swaync é o daemon que recebe (notify-send → dbus → swaync); category agrupa no centro
      notify-send -a GitHub -i github -h string:category:github "🔔 $repo" "$title" 2>/dev/null || true
      printf '%s\n' "$id" >> "$SEEN"
    done
  fi
  # poda o seen pra não crescer infinito: mantém só ids ainda presentes
  if [ -s "$SEEN" ]; then
    keep="$(printf '%s' "$json" | jq -r '.[].id')"
    grep -Fxf <(printf '%s\n' "$keep") "$SEEN" 2>/dev/null > "$SEEN.tmp" && mv "$SEEN.tmp" "$SEEN" || true
  fi
fi

# emite a lista (com web url) pro widget
printf '%s' "$json" | jq -c --arg dummy "" '[.[] | . + {url: (.api | sub("api\\.github\\.com/repos";"github.com") | sub("/pulls/";"/pull/"))}]'
