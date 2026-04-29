#!/bin/bash
# stop-teams.sh - 指定プロジェクトの全 kiro セッション + notifier を停止 (汎用版)
#
# Usage:
#   stop-teams.sh [project-root] [initiative]
#
# Examples:
#   stop-teams.sh                       # pwd から全セッション停止
#   stop-teams.sh ~/Desktop/projects/orera           # 指定プロジェクトの全停止
#   stop-teams.sh ~/Desktop/projects/orera blog      # 1案件のみ停止 (chief は残す)

set +e

resolve_project_root() {
  if [ "$#" -gt 0 ] && [ -d "$1" ]; then
    echo "$1"
    return 0
  fi
  if git rev-parse --show-toplevel >/dev/null 2>&1; then
    git rev-parse --show-toplevel
    return 0
  fi
  pwd
}

PROJECT_ROOT=""
INITIATIVE=""

if [ "$#" -gt 0 ] && [ -d "$1" ]; then
  PROJECT_ROOT="$1"
  shift
fi
if [ -z "$PROJECT_ROOT" ]; then
  PROJECT_ROOT="$(resolve_project_root)"
fi
if [ "$#" -gt 0 ]; then
  INITIATIVE="$1"
fi

PROJECT_NAME=$(basename "$PROJECT_ROOT")
SESSION_PREFIX="kiro-${PROJECT_NAME}"

stop_session_and_notifier() {
  local session_name="$1"
  local notifier_pattern="$2"  # pgrep pattern, e.g. "team-notifier.sh blog"
  local pane_dir="$3"          # dir containing .pane_* and *.sent files

  if tmux has-session -t "$session_name" 2>/dev/null; then
    tmux kill-session -t "$session_name"
    echo "  [stopped session] $session_name"
  fi

  if [ -n "$notifier_pattern" ]; then
    pkill -f "$notifier_pattern" 2>/dev/null && \
      echo "  [killed notifier] $notifier_pattern"
  fi

  if [ -n "$pane_dir" ] && [ -d "$pane_dir" ]; then
    rm -f "$pane_dir/.pane_"* 2>/dev/null
    rm -f "$pane_dir/"*.sent 2>/dev/null
    rm -f "$pane_dir/"*.notified 2>/dev/null
  fi
}

echo "=== Stopping kiro sessions for: $PROJECT_NAME ==="

if [ -n "$INITIATIVE" ]; then
  # Stop only the specified initiative
  worktree="${PROJECT_ROOT}/../${PROJECT_NAME}-${INITIATIVE}"
  tasks_dir="$worktree/kiro-team/teams/${INITIATIVE}/tasks"
  results_dir="$worktree/kiro-team/teams/${INITIATIVE}/results"
  stop_session_and_notifier "${SESSION_PREFIX}-${INITIATIVE}" "team-notifier.sh ${INITIATIVE}" "$tasks_dir"
  rm -f "$results_dir/"*.notified 2>/dev/null
else
  # Stop all initiatives + chief
  for sess in $(tmux list-sessions -F "#{session_name}" 2>/dev/null | grep "^${SESSION_PREFIX}-"); do
    init=$(echo "$sess" | sed "s/^${SESSION_PREFIX}-//")
    if [ "$init" = "chief" ]; then
      stop_session_and_notifier "$sess" "chief-notifier.sh ${PROJECT_ROOT}" ""
    else
      worktree="${PROJECT_ROOT}/../${PROJECT_NAME}-${init}"
      tasks_dir="$worktree/kiro-team/teams/${init}/tasks"
      results_dir="$worktree/kiro-team/teams/${init}/results"
      stop_session_and_notifier "$sess" "team-notifier.sh ${init}" "$tasks_dir"
      rm -f "$results_dir/"*.notified 2>/dev/null
    fi
  done
fi

echo ""
echo "=== Done ==="
