#!/bin/bash
# status.sh - セッション状態と results/ の更新時刻を表示する
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

echo "=== kiro-team status ==="
echo ""
echo "Sessions:"
for agent_file in "$AGENTS_DIR"/*.json; do
  [ -f "$agent_file" ] || continue
  name=$(grep -o '"name"[[:space:]]*:[[:space:]]*"[^"]*"' "$agent_file" | grep -o '"[^"]*"$' | tr -d '"')
  if tmux list-windows -t "$SESSION_NAME" -F "#{window_name}" 2>/dev/null | grep -q "^${name}$"; then
    echo "  [running] $name"
  else
    echo "  [stopped] $name"
  fi
done

echo ""
echo "Results:"
if [ -d "$RESULTS_DIR" ]; then
  for result_file in "$RESULTS_DIR"/*.md; do
    [ -f "$result_file" ] || { echo "  (none)"; break; }
    name=$(basename "$result_file" .md)
    updated=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M:%S" "$result_file" 2>/dev/null || stat -c "%y" "$result_file" 2>/dev/null | cut -d. -f1)
    status=$(grep "^STATUS:" "$result_file" 2>/dev/null | head -1 | awk '{print $2}' || echo "unknown")
    echo "  $name: $status (updated: $updated)"
  done
else
  echo "  (results/ not found)"
fi
