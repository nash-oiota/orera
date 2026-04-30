#!/bin/bash
# stop-teams.sh - 指定プロジェクトの全 kiro セッション + notifier を停止 (汎用版)
#
# Usage:
#   stop-teams.sh [project-root] [initiative] [--clean]
#   stop-teams.sh --all [--clean]
#
# Examples:
#   stop-teams.sh                              # pwd から全セッション停止
#   stop-teams.sh blog                         # 1案件のみ停止
#   stop-teams.sh blog --clean                 # 1案件停止 + worktree 削除
#   stop-teams.sh --all                        # projects.conf の全案件を停止
#   stop-teams.sh --all --clean                # projects.conf の全案件停止 + worktree 削除
#   stop-teams.sh chief                        # chief のみ停止

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
CLEAN=0
ALL_MODE=0

if [ "$#" -gt 0 ] && [ -d "$1" ]; then
  PROJECT_ROOT="$1"
  shift
fi
if [ -z "$PROJECT_ROOT" ]; then
  PROJECT_ROOT="$(resolve_project_root)"
fi

while [ "$#" -gt 0 ]; do
  case "$1" in
    --clean) CLEAN=1; shift ;;
    --all)   ALL_MODE=1; shift ;;
    *) INITIATIVE="$1"; shift ;;
  esac
done

PROJECT_NAME=$(basename "$PROJECT_ROOT")
SESSION_PREFIX="kiro-${PROJECT_NAME}"

PROJECTS_DIR="$(dirname "$PROJECT_ROOT")"

# Remove worktrees created by setup-multi.sh for a given initiative
stop_multi_worktrees() {
  local initiative="$1"
  # Remove per-repo worktrees inside PROJECT_ROOT
  for worktree_dir in "${PROJECT_ROOT}"/*-"${initiative}"; do
    [ -d "$worktree_dir" ] || continue
    local repo_name
    repo_name="$(basename "$worktree_dir" | sed "s/-${initiative}$//")"
    local repo_dir="${PROJECTS_DIR}/${repo_name}"
    if [ -d "$repo_dir/.git" ]; then
      (cd "$repo_dir" && git worktree remove --force "$worktree_dir" 2>/dev/null) && \
        echo "  [removed worktree] $worktree_dir"
    fi
  done
}

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

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KIRO_TEAM_DIR="$(dirname "$SCRIPT_DIR")"
GLOBAL_PROJECTS_DIR="${KIRO_TEAM_PROJECTS_DIR:-$HOME/projects}"

echo "=== Stopping kiro sessions ==="

# --all: read projects.conf and stop each project
if [ "$ALL_MODE" -eq 1 ]; then
  CONF="${KIRO_TEAM_DIR}/projects.conf"
  if [ ! -f "$CONF" ]; then
    echo "Error: projects.conf not found at $CONF"
    exit 1
  fi
  while IFS= read -r line; do
    line="${line%%#*}"
    line="$(echo "$line" | xargs)"
    [ -z "$line" ] && continue
    IFS=':' read -r conf_project conf_init _ <<< "$line"
    [ -z "$conf_project" ] || [ -z "$conf_init" ] && continue
    conf_project_root="${GLOBAL_PROJECTS_DIR}/${conf_project}"
    PROJECT_ROOT="$conf_project_root"
    PROJECT_NAME=$(basename "$PROJECT_ROOT")
    SESSION_PREFIX="kiro-${PROJECT_NAME}"
    PROJECTS_DIR="$(dirname "$PROJECT_ROOT")"
    echo "--- $conf_project/$conf_init ---"
    worktree="${PROJECT_ROOT}/../${PROJECT_NAME}-${conf_init}"
    tasks_dir="$worktree/kiro-team/teams/${conf_init}/tasks"
    results_dir="$worktree/kiro-team/teams/${conf_init}/results"
    stop_session_and_notifier "${SESSION_PREFIX}-${conf_init}" "team-notifier.sh ${conf_init}" "$tasks_dir"
    rm -f "$results_dir/"*.notified 2>/dev/null
    if [ "$CLEAN" -eq 1 ]; then
      [ -d "$worktree" ] && git -C "$PROJECT_ROOT" worktree remove --force "$worktree" 2>/dev/null && \
        echo "  [removed worktree] $worktree"
      stop_multi_worktrees "$conf_init"
    fi
  done < "$CONF"
  # Stop global chief
  stop_session_and_notifier "kiro-chief" "chief-notifier.sh" ""
  echo ""
  echo "=== Done ==="
  exit 0
fi

echo "=== Stopping kiro sessions for: $PROJECT_NAME ==="

if [ -n "$INITIATIVE" ]; then
  if [ "$INITIATIVE" = "chief" ]; then
    # Stop global chief session
    stop_session_and_notifier "kiro-chief" "chief-notifier.sh" ""
  else
    # Stop only the specified initiative
    worktree="${PROJECT_ROOT}/../${PROJECT_NAME}-${INITIATIVE}"
    tasks_dir="$worktree/kiro-team/teams/${INITIATIVE}/tasks"
    results_dir="$worktree/kiro-team/teams/${INITIATIVE}/results"
    stop_session_and_notifier "${SESSION_PREFIX}-${INITIATIVE}" "team-notifier.sh ${INITIATIVE}" "$tasks_dir"
    rm -f "$results_dir/"*.notified 2>/dev/null
    # Clean up worktrees only if --clean
    if [ "$CLEAN" -eq 1 ]; then
      # Single-repo worktree
      [ -d "$worktree" ] && git -C "$PROJECT_ROOT" worktree remove --force "$worktree" 2>/dev/null && \
        echo "  [removed worktree] $worktree"
      # Multi-repo worktrees
      stop_multi_worktrees "$INITIATIVE"
    fi
  fi
else
  # Stop all initiatives + chief
  for sess in $(tmux list-sessions -F "#{session_name}" 2>/dev/null | grep "^${SESSION_PREFIX}-"); do
    init=$(echo "$sess" | sed "s/^${SESSION_PREFIX}-//")
    if [ "$init" = "chief" ]; then
      stop_session_and_notifier "kiro-chief" "chief-notifier.sh" ""
    else
      worktree="${PROJECT_ROOT}/../${PROJECT_NAME}-${init}"
      tasks_dir="$worktree/kiro-team/teams/${init}/tasks"
      results_dir="$worktree/kiro-team/teams/${init}/results"
      stop_session_and_notifier "$sess" "team-notifier.sh ${init}" "$tasks_dir"
      rm -f "$results_dir/"*.notified 2>/dev/null
      if [ "$CLEAN" -eq 1 ]; then
        [ -d "$worktree" ] && git -C "$PROJECT_ROOT" worktree remove --force "$worktree" 2>/dev/null && \
          echo "  [removed worktree] $worktree"
        stop_multi_worktrees "$init"
      fi
    fi
  done
fi

echo ""
echo "=== Done ==="


