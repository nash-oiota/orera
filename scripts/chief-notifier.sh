#!/bin/bash
# chief-notifier.sh - グローバル Chief PdM 用 notifier
# Usage: ./chief-notifier.sh <projects-dir>
# Example: ./chief-notifier.sh /Users/naoish/projects
#
# 役割:
# - 1時間ごとに chief-pdm に全プロジェクト・全案件チェックを促す
# - 各案件の team-notifier ログを監視し、長時間応答なしの案件を検出して chief に通知

set +e
PROJECTS_DIR="${1:?Usage: $0 <projects-dir>}"
SESSION_NAME="kiro-chief"
POLL_INTERVAL=5
PROMPT_TIMEOUT=60
PING_INTERVAL=3600    # 1 hour
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

# Discover all active initiatives across all projects under PROJECTS_DIR
discover_all_initiatives() {
  for project_dir in "$PROJECTS_DIR"/*/; do
    [ -d "$project_dir" ] || continue
    local project_name
    project_name=$(basename "$project_dir")
    # Look for kiro-team/teams/<initiative>/ directories
    for teams_dir in "$project_dir"kiro-team/teams/*/; do
      [ -d "$teams_dir" ] || continue
      local initiative
      initiative=$(basename "$teams_dir")
      echo "${project_name}:${initiative}:${teams_dir}"
    done
  done
}

check_stalled_initiatives() {
  local stalled=""
  while IFS=: read -r project initiative teams_dir; do
    [ -z "$initiative" ] && continue
    local notifier_log="${teams_dir}tasks/.notifier.log"
    if [ -f "$notifier_log" ]; then
      local last_mtime now_epoch
      last_mtime=$(stat -f %m "$notifier_log" 2>/dev/null || stat -c %Y "$notifier_log" 2>/dev/null)
      now_epoch=$(date +%s)
      if [ -n "$last_mtime" ] && (( now_epoch - last_mtime > STALL_THRESHOLD )); then
        stalled="${stalled} ${project}/${initiative}"
      fi
    fi
  done < <(discover_all_initiatives)
  echo "$stalled"
}

notify_chief_pdm_result() {
  local project="$1" initiative="$2" result_file="$3"
  local chief_pane
  chief_pane=$(get_chief_pane)
  [ -z "$chief_pane" ] && return 0
  wait_for_prompt "$chief_pane" || return 0
  tmux send-keys -t "$chief_pane" "[SYSTEM] ${project}/${initiative} PDM updated results. Check ${result_file}" Enter
  log "NOTIFIED chief about ${project}/${initiative} pdm results"
}

check_pdm_results() {
  while IFS=: read -r project initiative teams_dir; do
    [ -z "$initiative" ] && continue
    local result_file="${teams_dir}results/${initiative}-pdm.md"
    [ -f "$result_file" ] || continue
    local notified_file="${teams_dir}results/${initiative}-pdm.chief-notified"
    if [ -f "$notified_file" ] && [ "$notified_file" -nt "$result_file" ]; then
      continue
    fi
    notify_chief_pdm_result "$project" "$initiative" "$result_file"
    touch "$notified_file"
  done < <(discover_all_initiatives)
}

log "chief-notifier started. Monitoring all projects under: $PROJECTS_DIR"

LAST_PING=0

while true; do
  check_pdm_results

  NOW=$(date +%s)
  if (( NOW - LAST_PING >= PING_INTERVAL )); then
    chief_pane=$(get_chief_pane)
    if [ -n "$chief_pane" ] && wait_for_prompt "$chief_pane"; then
      stalled=$(check_stalled_initiatives)
      stalled_msg=""
      if [ -n "$stalled" ]; then
        stalled_msg=" [警告] 長時間応答なしの案件:${stalled}"
      fi

      tmux send-keys -t "$chief_pane" "全プロジェクト定期チェック: ${PROJECTS_DIR} 配下の全プロジェクト・全案件 (kiro-team/teams/<initiative>/) の plans/ と results/<initiative>-pdm.md を確認し、以下を報告してください。(1) 案件ごとの進捗と KPI 達成状況 (2) BLOCKED/QUESTION の放置がないか (3) プロジェクト間の整合性 (依存関係・方針の齟齬) (4) 全体の優先順位の見直し提案。判断が必要なものはユーザーに提起してください。${stalled_msg}" Enter
      log "PING chief (autonomous check)${stalled:+ stalled:$stalled}"
      LAST_PING=$NOW
    fi
  fi

  sleep "$POLL_INTERVAL"
done scripts/team-notifier.sh
#!/bin/bash
# chief-notifier.sh - グローバル Chief PdM 用 notifier
# Usage: ./chief-notifier.sh <projects-dir>
# Example: ./chief-notifier.sh /Users/naoish/projects
#
# 役割:
# - 1時間ごとに chief-pdm に全プロジェクト・全案件チェックを促す
# - 各案件の team-notifier ログを監視し、長時間応答なしの案件を検出して chief に通知

set +e
PROJECTS_DIR="${1:?Usage: $0 <projects-dir>}"
SESSION_NAME="kiro-chief"
POLL_INTERVAL=5
PROMPT_TIMEOUT=60
PING_INTERVAL=3600    # 1 hour
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

# Discover all active initiatives across all projects under PROJECTS_DIR
discover_all_initiatives() {
  for project_dir in "$PROJECTS_DIR"/*/; do
    [ -d "$project_dir" ] || continue
    local project_name
    project_name=$(basename "$project_dir")
    # Look for kiro-team/teams/<initiative>/ directories
    for teams_dir in "$project_dir"kiro-team/teams/*/; do
      [ -d "$teams_dir" ] || continue
      local initiative
      initiative=$(basename "$teams_dir")
      echo "${project_name}:${initiative}:${teams_dir}"
    done
  done
}

check_stalled_initiatives() {
  local stalled=""
  while IFS=: read -r project initiative teams_dir; do
    [ -z "$initiative" ] && continue
    local notifier_log="${teams_dir}tasks/.notifier.log"
    if [ -f "$notifier_log" ]; then
      local last_mtime now_epoch
      last_mtime=$(stat -f %m "$notifier_log" 2>/dev/null || stat -c %Y "$notifier_log" 2>/dev/null)
      now_epoch=$(date +%s)
      if [ -n "$last_mtime" ] && (( now_epoch - last_mtime > STALL_THRESHOLD )); then
        stalled="${stalled} ${project}/${initiative}"
      fi
    fi
  done < <(discover_all_initiatives)
  echo "$stalled"
}

notify_chief_pdm_result() {
  local project="$1" initiative="$2" result_file="$3"
  local chief_pane
  chief_pane=$(get_chief_pane)
  [ -z "$chief_pane" ] && return 0
  wait_for_prompt "$chief_pane" || return 0
  tmux send-keys -t "$chief_pane" "[SYSTEM] ${project}/${initiative} PDM updated results. Check ${result_file}" Enter
  log "NOTIFIED chief about ${project}/${initiative} pdm results"
}

check_pdm_results() {
  while IFS=: read -r project initiative teams_dir; do
    [ -z "$initiative" ] && continue
    local result_file="${teams_dir}results/${initiative}-pdm.md"
    [ -f "$result_file" ] || continue
    local notified_file="${teams_dir}results/${initiative}-pdm.chief-notified"
    if [ -f "$notified_file" ] && [ "$notified_file" -nt "$result_file" ]; then
      continue
    fi
    notify_chief_pdm_result "$project" "$initiative" "$result_file"
    touch "$notified_file"
  done < <(discover_all_initiatives)
}

log "chief-notifier started. Monitoring all projects under: $PROJECTS_DIR"

LAST_PING=0

while true; do
  check_pdm_results

  NOW=$(date +%s)
  if (( NOW - LAST_PING >= PING_INTERVAL )); then
    chief_pane=$(get_chief_pane)
    if [ -n "$chief_pane" ] && wait_for_prompt "$chief_pane"; then
      stalled=$(check_stalled_initiatives)
      stalled_msg=""
      if [ -n "$stalled" ]; then
        stalled_msg=" [警告] 長時間応答なしの案件:${stalled}"
      fi

      tmux send-keys -t "$chief_pane" "全プロジェクト定期チェック: ${PROJECTS_DIR} 配下の全プロジェクト・全案件 (kiro-team/teams/<initiative>/) の plans/ と results/<initiative>-pdm.md を確認し、以下を報告してください。(1) 案件ごとの進捗と KPI 達成状況 (2) BLOCKED/QUESTION の放置がないか (3) プロジェクト間の整合性 (依存関係・方針の齟齬) (4) 全体の優先順位の見直し提案。判断が必要なものはユーザーに提起してください。${stalled_msg}" Enter
      log "PING chief (autonomous check)${stalled:+ stalled:$stalled}"
      LAST_PING=$NOW
    fi
  fi

  sleep "$POLL_INTERVAL"
