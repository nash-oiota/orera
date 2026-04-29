#!/bin/bash
# chief-notifier.sh - Chief PdM 用 notifier (汎用版)
# Usage: ./chief-notifier.sh <project-root>
# Example: ./chief-notifier.sh /Users/naoish/Desktop/projects/orera
#
# 役割:
# - 1時間ごとに chief-pdm に全案件チェックを促す
# - 各案件の team-notifier ログを監視し、長時間応答なしの案件を検出して chief に通知

set +e
PROJECT_ROOT="${1:?Usage: $0 <project-root>}"
PROJECT_NAME=$(basename "$PROJECT_ROOT")
SESSION_NAME="kiro-${PROJECT_NAME}-chief"
POLL_INTERVAL=5
PROMPT_TIMEOUT=60
PING_INTERVAL=3600  # 1 hour
STALL_THRESHOLD=3600  # 1 hour without notifier activity = stalled

log() {
  echo "[$(date +%H:%M:%S)] [chief] $*"
}

wait_for_prompt() {
  local pane="$1"
  local elapsed=0
  while [ "$elapsed" -lt "$PROMPT_TIMEOUT" ]; do
    local snap1 snap2
    snap1=$(tmux capture-pane -t "$pane" -p 2>/dev/null | tail -5)
    sleep 2
    snap2=$(tmux capture-pane -t "$pane" -p 2>/dev/null | tail -5)
    if [ "$snap1" = "$snap2" ] && ! echo "$snap2" | grep -qE "Thinking"; then
      return 0
    fi
    elapsed=$((elapsed + 2))
  done
  return 1
}

get_chief_pane() {
  tmux list-panes -t "$SESSION_NAME" -F "#{pane_id}" 2>/dev/null | head -1
}

# Discover active initiatives by scanning sibling worktrees
discover_initiatives() {
  local parent_dir
  parent_dir="$(dirname "$PROJECT_ROOT")"
  local initiatives=()
  for d in "$parent_dir"/${PROJECT_NAME}-*; do
    [ -d "$d" ] || continue
    local name
    name=$(basename "$d" | sed "s/^${PROJECT_NAME}-//")
    [ -n "$name" ] && initiatives+=("$name:$d")
  done
  printf '%s\n' "${initiatives[@]}"
}

check_stalled_initiatives() {
  local stalled=""
  while IFS=: read -r initiative worktree; do
    [ -z "$initiative" ] && continue
    local notifier_log="${worktree}/kiro-team/teams/${initiative}/tasks/.notifier.log"
    if [ -f "$notifier_log" ]; then
      local last_mtime
      last_mtime=$(stat -f %m "$notifier_log" 2>/dev/null || stat -c %Y "$notifier_log" 2>/dev/null)
      local now_epoch
      now_epoch=$(date +%s)
      if [ -n "$last_mtime" ] && (( now_epoch - last_mtime > STALL_THRESHOLD )); then
        stalled="${stalled} ${initiative}"
      fi
    fi
  done < <(discover_initiatives)
  echo "$stalled"
}

log "chief-notifier started. Monitoring project: $PROJECT_NAME"

LAST_PING=0

while true; do
  NOW=$(date +%s)
  if (( NOW - LAST_PING >= PING_INTERVAL )); then
    chief_pane=$(get_chief_pane)
    if [ -n "$chief_pane" ] && wait_for_prompt "$chief_pane"; then
      stalled=$(check_stalled_initiatives)
      stalled_msg=""
      if [ -n "$stalled" ]; then
        stalled_msg=" [警告] 長時間応答なしの案件:${stalled}"
      fi

      tmux send-keys -t "$chief_pane" "全案件定期チェック: 各案件 (kiro-team/teams/<initiative>/) の plans/ と results/<initiative>-pdm.md を確認し、以下を報告してください。(1) 案件ごとの進捗と KPI 達成状況 (2) BLOCKED/QUESTION の放置がないか (3) 案件間の整合性 (依存関係・方針の齟齬) (4) 全体の優先順位の見直し提案。判断が必要なものはユーザーに提起してください。${stalled_msg}" Enter
      log "PING chief (autonomous check)${stalled:+ stalled:$stalled}"
      LAST_PING=$NOW
    fi
  fi

  sleep "$POLL_INTERVAL"
done
