#!/bin/bash
# team-notifier.sh - 案件 (initiative) 単位の notifier (汎用版)
# Usage: ./team-notifier.sh <initiative> <worktree-root> [ping-interval-seconds]
# Example: ./team-notifier.sh mobile-cv-improve /Users/naoish/Desktop/projects/orera-mobile-cv-improve
# Example (ping disabled): ./team-notifier.sh mobile-cv-improve /Users/.../orera-mobile-cv-improve 0

set +e
INITIATIVE="${1:?Usage: $0 <initiative> <worktree-root> [ping-interval-seconds]}"
WORKTREE_DIR="${2:-$(pwd)}"
PING_INTERVAL="${3:-1800}"  # default 30 min, 0 disables
# Derive base project name (strip initiative suffix from worktree dir name)
PROJECT_NAME=$(basename "$WORKTREE_DIR" | sed "s/-${INITIATIVE}$//")

TASKS_DIR="$WORKTREE_DIR/kiro-team/teams/${INITIATIVE}/tasks"
RESULTS_DIR="$WORKTREE_DIR/kiro-team/teams/${INITIATIVE}/results"
SESSION_NAME="kiro-${PROJECT_NAME}-${INITIATIVE}"
POLL_INTERVAL=5
PROMPT_TIMEOUT=60

mkdir -p "$TASKS_DIR" "$RESULTS_DIR"

log() {
  echo "[$(date +%H:%M:%S)] [$INITIATIVE] $*"
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

  [ -f "$pane_file" ] && [ -s "$pane_file" ] && return 0

  touch "$pane_file"
  log "Starting session for $agent..."

  # Use new-window (not split-window) to keep the layout clean
  local new_pane
  new_pane=$(tmux new-window -t "$SESSION_NAME" -n "$agent" -c "$WORKTREE_DIR" -P -F "#{pane_id}")
  echo "$new_pane" > "$pane_file"
  tmux send-keys -t "$new_pane" "kiro-cli chat --agent $agent" Enter
  sleep 15
}

deliver_task() {
  local agent="$1"
  local task_file="$TASKS_DIR/${agent}.md"
  local pane
  pane=$(get_agent_pane "$agent")
  [ -z "$pane" ] && return 1
  local abs_path
  abs_path="$(cd "$(dirname "$task_file")" && pwd)/$(basename "$task_file")"
  tmux send-keys -t "$pane" "次のタスクファイルを読んで実行してください: $abs_path" Enter
  touch "$TASKS_DIR/${agent}.sent"
  log "TASK_SENT $agent TASK_ID:$(grep "^TASK_ID:" "$task_file" 2>/dev/null | head -1 | awk '{print $2}')"
}

notify_pdm() {
  local agent="$1"
  local pdm_pane
  pdm_pane=$(cat "$TASKS_DIR/.pane_${INITIATIVE}-pdm" 2>/dev/null)
  [ -z "$pdm_pane" ] && return 0
  tmux send-keys -t "$pdm_pane" "[SYSTEM] ${agent} updated results. Check kiro-team/teams/${INITIATIVE}/results/${agent}.md" Enter
  log "NOTIFIED pdm about $agent results"
}

log "notifier started. Monitoring $TASKS_DIR/ (ping_interval=${PING_INTERVAL}s)"

LAST_PING=0

while true; do
  # Periodic autonomous ping (skipped if PING_INTERVAL is 0)
  if (( PING_INTERVAL > 0 )); then
    NOW=$(date +%s)
    if (( NOW - LAST_PING >= PING_INTERVAL )); then
      pdm_pane=$(cat "$TASKS_DIR/.pane_${INITIATIVE}-pdm" 2>/dev/null)
      if [ -n "$pdm_pane" ] && wait_for_prompt "${INITIATIVE}-pdm"; then
        tmux send-keys -t "$pdm_pane" "自律チェック: 各スペシャリストの進捗を確認してください。アイドル中のスペシャリストに次のタスクを委譲、ブロッカーがあれば解消。全タスク完了なら次のイテレーションを計画してください。本当に外部入力待ちの場合のみ '待機中: <理由>' と報告。" Enter
        log "PING pdm (autonomous check)"
        LAST_PING=$NOW
      fi
    fi
  fi

  # Check for new tasks
  for task_file in "$TASKS_DIR"/*.md; do
    [ -f "$task_file" ] || continue
    agent=$(basename "$task_file" .md)
    sent_file="$TASKS_DIR/${agent}.sent"

    if [ -f "$sent_file" ] && [ "$sent_file" -nt "$task_file" ]; then
      continue
    fi

    [[ "$agent" =~ ^[a-zA-Z0-9_-]+$ ]] || continue

    # Validate agent definition exists
    if [ ! -f "$WORKTREE_DIR/.kiro/agents/${agent}.json" ]; then
      log "ERROR: agent '$agent' not found in .kiro/agents/. Skipping task."
      pdm_pane=$(cat "$TASKS_DIR/.pane_${INITIATIVE}-pdm" 2>/dev/null)
      if [ -n "$pdm_pane" ]; then
        tmux send-keys -t "$pdm_pane" "[SYSTEM ERROR] タスクファイル '${agent}.md' に対応するエージェント定義 (.kiro/agents/${agent}.json) が存在しません。setup-teams.sh で --roles に該当ロールを含めて再実行してください。" Enter
      fi
      touch "$TASKS_DIR/${agent}.sent"
      continue
    fi

    ensure_session "$agent" || continue

    if ! wait_for_prompt "$agent"; then
      continue
    fi

    deliver_task "$agent"
  done

  # Check for new results (notify PdM)
  for result_file in "$RESULTS_DIR"/*.md; do
    [ -f "$result_file" ] || continue
    agent=$(basename "$result_file" .md)
    notified_file="$RESULTS_DIR/${agent}.notified"

    if [ -f "$notified_file" ] && [ "$notified_file" -nt "$result_file" ]; then
      continue
    fi

    notify_pdm "$agent"
    touch "$notified_file"
  done

  sleep "$POLL_INTERVAL"
done
