#!/bin/bash
# stop.sh - 全セッションを停止する
# Usage:
#   ./scripts/stop.sh            # 通常停止（tasks/results はそのまま）
#   ./scripts/stop.sh --archive  # アーカイブして停止
#   ./scripts/stop.sh --clean    # 削除して停止（完全リセット）

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

MODE="${1:-}"

if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
  tmux kill-session -t "$SESSION_NAME"
  echo "kiro-team stopped."
else
  echo "No session '$SESSION_NAME' found." >&2
fi

case "$MODE" in
  --archive)
    archive_dir="archive/$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$archive_dir"
    mv tasks/ results/ "$archive_dir/" 2>/dev/null || true
    echo "Archived to $archive_dir"
    ;;
  --clean)
    rm -rf tasks/ results/
    echo "Cleaned tasks/ and results/"
    ;;
esac
