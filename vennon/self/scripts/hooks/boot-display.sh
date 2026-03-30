#!/usr/bin/env bash
# Boot display — ASCII banner + system status (stderr only, terminal visual)
# Extracted from session-start.sh to reduce monolith size.

_lab_dir="/workspace/host"
# Detecta VCS: jj ou git
if jj -R "$_lab_dir" root >/dev/null 2>&1; then
  _worktrees=$(jj -R "$_lab_dir" workspace list 2>/dev/null | wc -l | tr -d ' ')
  _git_branch=$(jj -R "$_lab_dir" log --no-graph -T 'bookmarks.map(|b| b.name()).join(",") ++ "\n"' -r @ 2>/dev/null | head -1 || echo "?")
  [ -z "$_git_branch" ] && _git_branch=$(jj -R "$_lab_dir" log --no-graph -T 'change_id.short() ++ "\n"' -r @ 2>/dev/null | head -1 || echo "?")
  _git_dirty=$(jj -R "$_lab_dir" diff --summary 2>/dev/null | wc -l | tr -d ' ')
  _git_ahead=0
else
  _worktrees=$(git -C "$_lab_dir" worktree list 2>/dev/null | wc -l | tr -d ' ')
  _git_branch=$(git -C "$_lab_dir" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "?")
  _git_dirty=$(git -C "$_lab_dir" status --porcelain 2>/dev/null | wc -l | tr -d ' ')
  _git_ahead=$(git -C "$_lab_dir" rev-list @{u}..HEAD 2>/dev/null | wc -l | tr -d ' ')
fi
_todo_count=$(ls /workspace/obsidian/bedrooms/_waiting/*.md 2>/dev/null | wc -l | tr -d ' ')
_mem_count=$(ls "$HOME/.claude/projects/-workspace-mnt/memory/"*.md 2>/dev/null | wc -l | tr -d ' ')
_h_off=$([ "$HEADLESS" = "1" ] && echo "ON" || echo "OFF")
_d_on=$([ "$IN_DOCKER" = "1" ] && echo "ON" || echo "OFF")
_z_on=$([ "$HOST_ATTACHED" = "1" ] && echo "ON" || echo "OFF")

printf "\n"
printf "\033[35m"
printf "  ███████╗██╗ ██████╗ ███╗   ██╗    ██╗      █████╗ ██████╗ \n"
printf "     ███╔╝██║██╔═══██╗████╗  ██║    ██║     ██╔══██╗██╔══██╗\n"
printf "    ███╔╝ ██║██║   ██║██╔██╗ ██║    ██║     ███████║██████╔╝\n"
printf "   ███╔╝  ██║██║   ██║██║╚██╗██║    ██║     ██╔══██║██╔══██╗\n"
printf "  ███████╗██║╚██████╔╝██║ ╚████║    ███████╗██║  ██║██████╔╝\n"
printf "  ╚══════╝╚═╝ ╚═════╝ ╚═╝  ╚═══╝    ╚══════╝╚═╝  ╚═╝╚═════╝ \n"
printf "\033[0m\n"
printf "  %-22s %s\n" "headless" "$_h_off" "in_docker" "$_d_on" "host_attached" "$_z_on" "autocommit" "$AUTOCOMMIT" "personality" "$PERSONALITY"
printf "\n"
printf "  %-22s %s\n" "container_up" "$_uptime" "worktrees" "$_worktrees active" "inbox" "$_inbox items"
printf "\n"
printf "  %-12s .........  OK    [  12ms]\n" "BOOT"
printf "  %-12s .........  OK    [  23ms]  %s  ↑%s  %s dirty\n" "GIT" "$_git_branch" "$_git_ahead" "$_git_dirty"
printf "  %-12s .........  OK    [systemd]  » todo: %s\n" "TASKS" "$_todo_count"
[ $(( RANDOM % 3 )) -eq 0 ] && printf "  %-12s ..ʕ·ᴥ·ʔ..  LIER [   1ms]\n" "DIGNITY"
printf "  %-12s .........  OK    [  56ms]\n" "PERSONA"
printf "  %-12s .........  OK    [  19ms]  %s files\n" "MEMORY" "$_mem_count"
printf "  %-12s .........  OK    [ 142ms]\n" "API_USAGE"

_usage_file="/workspace/host/.ephemeral/usage-bar.txt"
[ -f "$_usage_file" ] || _usage_file="${WS:-.}/.ephemeral/usage-bar.txt"
[ -f "$_usage_file" ] || _usage_file="$HOME/.claude/.ephemeral/usage-bar.txt"
[ -f "$_usage_file" ] && printf "  %40s%s\n" "" "$(tail -1 "$_usage_file")"
printf "\n"
