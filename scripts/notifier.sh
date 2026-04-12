#!/bin/bash
# notifier.sh - tasks/ を監視し、specialist がプロンプト待ちのときにタスクを配送する
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

LOG_FILE="$LOG_DIR/session-$(ls -t "$LOG_DIR"/session-*.log 2>/dev/null | head -1 | xargs basename 2>/dev/null || echo "session-$(date +%Y%m%d-%H%M%S).log")"
mkdir -p "$LOG_DIR"

log() {
  echo "[$(date +%H:%M:%S)] $*" | tee -a "$LOG_FILE"
}

get_agent_pane() {
  local agent="$1"
  cat "$TASKS_DIR/.pane_${agent}" 2>/dev/null
}

wait_for_prompt() {
  local agent="$1"
  local pane
  pane=$(get_agent_pane "$agent")
  [ -z "$pane" ] && return 1
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

ensure_session() {
  local agent="$1"
  local pane_file="$TASKS_DIR/.pane_${agent}"

  # 既存ペインIDファイルがあればスキップ
  [ -f "$pane_file" ] && return 0

  # 先にファイルを作ってロック（重複起動防止）
  touch "$pane_file"

  echo "Starting session for $agent..."

  local specialist_pane
  specialist_pane=$(cat "$TASKS_DIR/.specialist_pane" 2>/dev/null)

  if [ -n "$specialist_pane" ]; then
    local new_pane
    # 最初の specialist は pdm を左右分割、2人目以降は前の specialist を上下分割
    if [ "$specialist_pane" = "$(cat "$TASKS_DIR/.pdm_pane" 2>/dev/null)" ]; then
      new_pane=$(tmux split-window -h -t "$specialist_pane" -p 40 -P -F "#{pane_id}")
    else
      new_pane=$(tmux split-window -v -t "$specialist_pane" -p 50 -P -F "#{pane_id}")
    fi
    echo "$new_pane" > "$pane_file"
    echo "$new_pane" > "$TASKS_DIR/.specialist_pane"
    tmux send-keys -t "$new_pane" "kiro-cli chat --agent $agent" Enter
  else
    tmux new-window -t "$SESSION_NAME" -n "$agent"
    echo "$SESSION_NAME:$agent" > "$pane_file"
    tmux send-keys -t "$SESSION_NAME:$agent" "kiro-cli chat --agent $agent" Enter
  fi
  sleep "$STARTUP_WAIT"
}

deliver_task() {
  local agent="$1"
  local task_content="$2"
  local pane
  pane=$(get_agent_pane "$agent")
  [ -z "$pane" ] && { echo "Warning: pane for $agent not found" >&2; return 1; }
  tmux send-keys -t "$pane" "$task_content" Enter || { echo "Warning: failed to send to $agent" >&2; return 1; }
  touch "$TASKS_DIR/${agent}.sent"
  log "TASK_SENT    $agent  TASK_ID:$(grep "^TASK_ID:" "$TASKS_DIR/${agent}.md" 2>/dev/null | head -1 | awk '{print $2}')"
  echo "Delivered task to $agent"
}

echo "notifier.sh started. Monitoring $TASKS_DIR/ ..."

while true; do
  for task_file in "$TASKS_DIR"/*.md; do
    [ -f "$task_file" ] || continue
    agent=$(basename "$task_file" .md)
    sent_file="$TASKS_DIR/${agent}.sent"

    # 送信済みマークがあり、タスクファイルより新しければスキップ
    if [ -f "$sent_file" ] && [ "$sent_file" -nt "$task_file" ]; then
      continue
    fi

    # エージェント名検証
    [[ "$agent" =~ ^[a-zA-Z0-9_-]+$ ]] || { echo "Warning: invalid agent name '$agent', skipping" >&2; continue; }

    # セッション確保
    ensure_session "$agent" || { echo "Warning: failed to start session for $agent" >&2; continue; }

    # プロンプト待ち確認
    if ! wait_for_prompt "$agent"; then
      echo "Warning: $agent prompt timeout, will retry" >&2
      continue
    fi

    # タスク送信
    task_content=$(cat "$task_file")
    deliver_task "$agent" "$task_content"
  done

  sleep "$POLL_INTERVAL"
done
