#!/bin/bash
# scheduler.sh - 定期的にファイル内の命令を PdM ペインにキックする
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

SCHEDULE_FILE="kiro-team/scheduled-task.md"
INTERVAL=${1:-1800}  # デフォルト30分（秒）

LOG_FILE="$LOG_DIR/scheduler-$(date +%Y%m%d-%H%M%S).log"
mkdir -p "$LOG_DIR"

log() {
  echo "[$(date +%H:%M:%S)] $*" | tee -a "$LOG_FILE"
}

wait_for_pdm() {
  local pdm_pane
  pdm_pane=$(cat "$TASKS_DIR/.pdm_pane" 2>/dev/null)
  [ -z "$pdm_pane" ] && return 1
  local elapsed=0
  while [ "$elapsed" -lt "$PROMPT_TIMEOUT" ]; do
    local snap1 snap2
    snap1=$(tmux capture-pane -t "$pdm_pane" -p 2>/dev/null | tail -5)
    sleep 2
    snap2=$(tmux capture-pane -t "$pdm_pane" -p 2>/dev/null | tail -5)
    if [ "$snap1" = "$snap2" ] && ! echo "$snap2" | grep -qE "Thinking"; then
      return 0
    fi
    elapsed=$((elapsed + 2))
  done
  return 1
}

log "scheduler.sh started. Interval: ${INTERVAL}s, File: $SCHEDULE_FILE"

while true; do
  if [ ! -f "$SCHEDULE_FILE" ]; then
    log "SKIP  $SCHEDULE_FILE not found"
    sleep "$INTERVAL"
    continue
  fi

  content=$(cat "$SCHEDULE_FILE")
  if [ -z "$content" ]; then
    log "SKIP  $SCHEDULE_FILE is empty"
    sleep "$INTERVAL"
    continue
  fi

  pdm_pane=$(cat "$TASKS_DIR/.pdm_pane" 2>/dev/null)
  if [ -z "$pdm_pane" ]; then
    log "SKIP  pdm pane not found"
    sleep "$INTERVAL"
    continue
  fi

  if ! wait_for_pdm; then
    log "SKIP  pdm busy, will retry next cycle"
    sleep "$INTERVAL"
    continue
  fi

  tmux send-keys -t "$pdm_pane" "次のファイルを読んで実行してください: $(pwd)/$SCHEDULE_FILE" Enter
  log "KICKED  $(head -1 "$SCHEDULE_FILE")"

  sleep "$INTERVAL"
done
