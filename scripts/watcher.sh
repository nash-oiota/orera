#!/bin/bash
# watcher.sh - results/ を監視し、PdM がプロンプト待ちのときのみ通知する
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

pdm_pane=$(cat "$TASKS_DIR/.pdm_pane" 2>/dev/null)
LOG_FILE="$LOG_DIR/session-$(date +%Y%m%d-%H%M%S).log"
mkdir -p "$LOG_DIR"

log() {
  echo "[$(date +%H:%M:%S)] $*" | tee -a "$LOG_FILE"
}

is_pdm_ready() {
  local snap1 snap2
  snap1=$(tmux capture-pane -t "$pdm_pane" -p 2>/dev/null | tail -5)
  sleep 5
  snap2=$(tmux capture-pane -t "$pdm_pane" -p 2>/dev/null | tail -5)
  [ "$snap1" = "$snap2" ] && ! echo "$snap2" | grep -qE "Thinking"
}

get_mtime() {
  stat -f "%m" "$1" 2>/dev/null || stat -c "%Y" "$1" 2>/dev/null
}

echo "watcher.sh started. Monitoring $RESULTS_DIR/ ..."

while true; do
  for result_file in "$RESULTS_DIR"/*.md; do
    [ -f "$result_file" ] || continue
    agent=$(basename "$result_file" .md)
    notified_file="$RESULTS_DIR/${agent}.notified"
    mtime_file="$RESULTS_DIR/${agent}.mtime"
    current_mtime=$(get_mtime "$result_file")

    # 前回から更新されているか確認
    prev_mtime=""
    [ -f "$mtime_file" ] && prev_mtime=$(cat "$mtime_file")
    if [ "$prev_mtime" = "$current_mtime" ]; then
      continue
    fi

    # mtime が変わったので .notified をリセット
    rm -f "$notified_file"

    # PdM がプロンプト待ちか確認
    if ! is_pdm_ready; then
      echo "PdM is busy, skipping notification for $agent"
      continue
    fi

    # 通知送信
    tmux send-keys -t "$pdm_pane" "[SYSTEM] $agent updated results. Check $RESULTS_DIR/${agent}.md" Enter
    touch "$notified_file"
    echo "$current_mtime" > "$mtime_file"
    status=$(grep "^STATUS:" "$result_file" 2>/dev/null | head -1 | awk '{print $2}')
    task_id=$(grep "^TASK_ID:" "$result_file" 2>/dev/null | head -1 | awk '{print $2}')
    log "TASK_DONE    $agent  TASK_ID:${task_id:-?}  STATUS:${status:-?}"
  done

  sleep "$POLL_INTERVAL"
done
