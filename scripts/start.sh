#!/bin/bash
# start.sh - PdM + watcher + notifier を起動する
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

validate_agent_name() {
  [[ "$1" =~ ^[a-zA-Z0-9_-]+$ ]] || { echo "Error: invalid agent name: $1" >&2; exit 1; }
}

validate_agents() {
  for agent_file in "$AGENTS_DIR"/*.json; do
    [ -f "$agent_file" ] || continue
    local filename
    filename=$(basename "$agent_file" .json)
    local name
    name=$(grep -o '"name"[[:space:]]*:[[:space:]]*"[^"]*"' "$agent_file" | grep -o '"[^"]*"$' | tr -d '"')
    if [ "$filename" != "$name" ]; then
      echo "Error: agent file '$filename.json' has name '$name'. They must match." >&2
      exit 1
    fi
    validate_agent_name "$name"
  done
}

check_dependencies() {
  command -v tmux >/dev/null 2>&1 || { echo "Error: tmux not found" >&2; exit 1; }
  command -v kiro-cli >/dev/null 2>&1 || { echo "Error: kiro-cli not found" >&2; exit 1; }
}

init_directories() {
  mkdir -p "$TASKS_DIR" "$RESULTS_DIR" "$LOG_DIR"
  # 古いペインIDをリセット（再起動時に誤判定を防ぐ）
  rm -f "$TASKS_DIR"/.pane_* "$TASKS_DIR"/.specialist_pane "$TASKS_DIR"/.pdm_pane
}

pdm_name=$(grep -o '"name"[[:space:]]*:[[:space:]]*"[^"]*"' "$AGENTS_DIR/kiro-team-pdm.json" | grep -o '"[^"]*"$' | tr -d '"')

setup_layout() {
  # セッション作成（pdm をペイン0に）
  tmux new-session -d -s "$SESSION_NAME" -x 220 -y 50
  tmux send-keys -t "$SESSION_NAME:0" "kiro-cli chat --agent $pdm_name" Enter

  # watcher と notifier は別ウィンドウ
  tmux new-window -t "$SESSION_NAME" -n "watcher"
  tmux send-keys -t "$SESSION_NAME:watcher" "bash $SCRIPT_DIR/watcher.sh" Enter

  tmux new-window -t "$SESSION_NAME" -n "notifier"
  tmux send-keys -t "$SESSION_NAME:notifier" "bash $SCRIPT_DIR/notifier.sh" Enter

  # specialist エリアの初期ペインIDとして pdm のペインIDを保存
  pdm_pane=$(tmux display-message -t "$SESSION_NAME:0.0" -p "#{pane_id}")
  echo "$pdm_pane" > "$TASKS_DIR/.specialist_pane"
  echo "$pdm_pane" > "$TASKS_DIR/.pdm_pane"

  # pdm にフォーカス
  tmux select-window -t "$SESSION_NAME:0"
  tmux select-pane -t "$SESSION_NAME:0.0"
}

check_dependencies
validate_agents
init_directories
setup_layout

echo "kiro-team started. Attaching..."
tmux attach -t "$SESSION_NAME:0.0"
