#!/bin/bash
# setup-teams.sh - 案件 (initiative) ごとに worktree + tmux セッション + agent 定義を起動
#
# Usage:
#   setup-teams.sh [project-root] <initiative> <branch> [options]
#   setup-teams.sh [project-root] --all [options]
#
# project-root を省略すると pwd / git toplevel を使用。
#
# Options:
#   --roles role1,role2,...  使用するロール (default: pdm,frontend,backend,qa,reviewer)
#   --no-ping                案件PdMへの定期自律ping (30分毎) を無効化
#   --all                    <project>/kiro-team/teams.conf に書かれた全案件を起動
#
# Examples:
#   setup-teams.sh ~/Desktop/projects/orera mobile-cv mobile-cv-main
#   setup-teams.sh mobile-cv mobile-cv-main                    # project-root=pwd
#   setup-teams.sh --all                                       # teams.conf 一括
#   setup-teams.sh ~/Desktop/projects/orera --all --no-ping

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KIRO_TEAM_DIR="$(dirname "$SCRIPT_DIR")"
GENERIC_TEMPLATES_DIR="$KIRO_TEAM_DIR/agents/templates"

usage() {
  cat <<USAGE
Usage:
  $0 [project-root] <initiative> <branch> [options]
  $0 [project-root] --all [options]

project-root を省略すると pwd または git toplevel を使用。

Options:
  --roles <list>   ロール (default: pdm,frontend,backend,qa,reviewer)
                   利用可能: pdm, frontend, backend, qa, reviewer, release,
                            debugger, researcher, architect, designer,
                            data, security, docs
  --no-ping        定期自律ping (30分) を無効化
  --all            <project-root>/kiro-team/teams.conf を読んで全案件を起動

teams.conf 形式 (1行1案件):
  <initiative>:<branch>[:<roles>]
USAGE
}

# ---- Resolve project-root (first positional arg if it's a directory, else pwd/git) ----
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

# ---- Argument parsing ----
PROJECT_ROOT=""
INITIATIVE=""
BRANCH=""
ALL_MODE=0
ROLES="pdm,frontend,backend,qa,reviewer"
PING_INTERVAL=1800

# Detect project-root (first positional if it's a directory)
if [ "$#" -gt 0 ] && [ -d "$1" ]; then
  PROJECT_ROOT="$1"
  shift
fi

# Remaining args
POSITIONAL=()
while [ "$#" -gt 0 ]; do
  case "$1" in
    --all)
      ALL_MODE=1
      shift
      ;;
    --roles)
      ROLES="$2"
      shift 2
      ;;
    --no-ping)
      PING_INTERVAL=0
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    -*)
      echo "Unknown option: $1"
      usage
      exit 1
      ;;
    *)
      POSITIONAL+=("$1")
      shift
      ;;
  esac
done

if [ -z "$PROJECT_ROOT" ]; then
  PROJECT_ROOT="$(resolve_project_root)"
fi

if [ "$ALL_MODE" -eq 0 ]; then
  if [ "${#POSITIONAL[@]}" -lt 2 ]; then
    echo "Error: <initiative> and <branch> required (or use --all)"
    usage
    exit 1
  fi
  INITIATIVE="${POSITIONAL[0]}"
  BRANCH="${POSITIONAL[1]}"
fi

PROJECT_NAME=$(basename "$PROJECT_ROOT")
PROJECT_TEMPLATES_DIR="$PROJECT_ROOT/.kiro/agent-templates"
PROJECTS_DIR="$(dirname "$PROJECT_ROOT")"
# For --all mode: PROJECTS_DIR is ~/projects (sibling of kiro-team or explicit)
GLOBAL_PROJECTS_DIR="${KIRO_TEAM_PROJECTS_DIR:-$HOME/projects}"
SESSION_PREFIX="kiro-${PROJECT_NAME}"
CHIEF_SESSION="kiro-chief"
CHIEF_DIR="${KIRO_TEAM_HOME:-$HOME/kiro-team}"
CHIEF_AGENTS_DIR="${HOME}/.kiro/agents"

# ---- Template lookup: project override → generic ----
resolve_template() {
  local role="$1"
  if [ -f "$PROJECT_TEMPLATES_DIR/team-${role}.json" ]; then
    echo "$PROJECT_TEMPLATES_DIR/team-${role}.json"
  elif [ -f "$GENERIC_TEMPLATES_DIR/team-${role}.json" ]; then
    echo "$GENERIC_TEMPLATES_DIR/team-${role}.json"
  else
    return 1
  fi
}

# ---- Start chief session if not running ----
start_chief_if_needed() {
  if tmux has-session -t "$CHIEF_SESSION" 2>/dev/null; then
    echo "  [skip] $CHIEF_SESSION already running"
    return 0
  fi

  # Generate chief-pdm.json in ~/.kiro/agents (global)
  mkdir -p "$CHIEF_AGENTS_DIR"
  if [ ! -f "${CHIEF_AGENTS_DIR}/chief-pdm.json" ]; then
    local chief_template="$GENERIC_TEMPLATES_DIR/chief-pdm.json"
    sed "s/{project}/global/g" "$chief_template" > "${CHIEF_AGENTS_DIR}/chief-pdm.json"
    echo "  [created] ${CHIEF_AGENTS_DIR}/chief-pdm.json"
  fi

  tmux new-session -d -s "$CHIEF_SESSION" -c "$GLOBAL_PROJECTS_DIR"
  tmux send-keys -t "$CHIEF_SESSION" "kiro-cli chat --agent chief-pdm" Enter
  local CHIEF_LOG="${HOME}/.kiro/chief-notifier.log"
  nohup "${SCRIPT_DIR}/chief-notifier.sh" "$GLOBAL_PROJECTS_DIR" \
    > "$CHIEF_LOG" 2>&1 &
  echo "  [started] $CHIEF_SESSION (chief-pdm + chief-notifier) @ $GLOBAL_PROJECTS_DIR"
}

# ---- Setup one initiative ----
setup_one() {
  local initiative="$1"
  local branch="$2"
  local roles="$3"
  local ping_interval="$4"

  local worktree_dir="${PROJECT_ROOT}/../${PROJECT_NAME}-${initiative}"
  local session_name="${SESSION_PREFIX}-${initiative}"

  echo ""
  echo "=========================================="
  echo "  Initiative: $initiative"
  echo "  Branch: feature/${branch}"
  echo "  Worktree: $worktree_dir"
  echo "  Roles: $roles"
  echo "  Ping: $([ "$ping_interval" = "0" ] && echo disabled || echo "${ping_interval}s")"
  echo "=========================================="

  # 1. Worktree
  cd "$PROJECT_ROOT"
  if [ -d "$worktree_dir" ]; then
    echo "  [skip worktree] $worktree_dir already exists"
  else
    if ! git show-ref --verify --quiet "refs/heads/feature/${branch}"; then
      local base_branch
      if git rev-parse --verify develop >/dev/null 2>&1; then
        base_branch=develop
      else
        base_branch=$(git rev-parse --abbrev-ref HEAD)
      fi
      git branch "feature/${branch}" "$base_branch"
      echo "  [branch created] feature/${branch} from $base_branch"
    fi
    git worktree add "$worktree_dir" "feature/${branch}"
    echo "  [worktree created] $worktree_dir"
  fi

  # 2. Agent definitions
  local agents_dir="${worktree_dir}/.kiro/agents"
  mkdir -p "$agents_dir"
  IFS=',' read -ra role_arr <<< "$roles"
  for role in "${role_arr[@]}"; do
    local template
    if ! template=$(resolve_template "$role"); then
      echo "  [error] template not found for role: $role"
      echo "         Searched: $PROJECT_TEMPLATES_DIR, $GENERIC_TEMPLATES_DIR"
      return 1
    fi
    local target="${agents_dir}/${initiative}-${role}.json"
    if [ -f "$target" ]; then
      echo "  [skip agent] ${initiative}-${role}.json"
    else
      sed "s/{team}/${initiative}/g" "$template" > "$target"
      echo "  [agent created] ${initiative}-${role}.json (from $(basename $(dirname $template))/$(basename $template))"
    fi
  done

  # 3. Tasks/results dirs
  local tasks_dir="${worktree_dir}/kiro-team/teams/${initiative}/tasks"
  local results_dir="${worktree_dir}/kiro-team/teams/${initiative}/results"
  local plans_dir="${worktree_dir}/kiro-team/teams/${initiative}/plans"
  mkdir -p "$tasks_dir" "$results_dir" "$plans_dir"

  # 4. npm install
  if [ -f "$worktree_dir/package.json" ] && [ ! -d "$worktree_dir/node_modules" ]; then
    echo "  [npm install] $worktree_dir"
    (cd "$worktree_dir" && npm install --silent)
  fi

  # 5. Initiative session
  if tmux has-session -t "$session_name" 2>/dev/null; then
    echo "  [skip session] $session_name already running"
  else
    tmux new-session -d -s "$session_name" -c "$worktree_dir"
    local pdm_pane
    pdm_pane=$(tmux list-panes -t "$session_name" -F "#{pane_id}" | head -1)
    echo "$pdm_pane" > "${tasks_dir}/.pane_${initiative}-pdm"
    tmux send-keys -t "$session_name" "kiro-cli chat --agent ${initiative}-pdm" Enter

    local notifier_log="${tasks_dir}/.notifier.log"
    nohup "${SCRIPT_DIR}/team-notifier.sh" "$initiative" "$worktree_dir" "$ping_interval" \
      > "$notifier_log" 2>&1 &
    echo "  [session started] $session_name (log: $notifier_log)"
  fi
}

# ---- Header ----
echo "=== Project: $PROJECT_NAME ($PROJECT_ROOT) ==="
if [ "$ALL_MODE" -eq 1 ]; then
  echo "=== Mode: --all (read projects.conf or teams.conf) ==="
else
  echo "=== Mode: single initiative ==="
fi
echo ""

# ---- Chief session ----
echo "=== Chief session ==="
start_chief_if_needed

# ---- Run setup ----
if [ "$ALL_MODE" -eq 1 ]; then
  # ~/kiro-team/projects.conf からグローバル定義を読む
  GLOBAL_CONF="${KIRO_TEAM_DIR}/projects.conf"

  if [ ! -f "$GLOBAL_CONF" ]; then
    echo ""
    echo "Error: projects.conf not found at $GLOBAL_CONF"
    echo "Hint: cp ${KIRO_TEAM_DIR}/projects.conf.example $GLOBAL_CONF and edit"
    exit 1
  fi

  CONF="$GLOBAL_CONF"
  echo "Using: $CONF"

  count=0
  while IFS= read -r line; do
    line="${line%%#*}"
    line="$(echo "$line" | xargs)"
    [ -z "$line" ] && continue

    IFS=':' read -r conf_project conf_init conf_branch conf_roles conf_repos <<< "$line"

    [ -z "$conf_project" ] || [ -z "$conf_init" ] || [ -z "$conf_branch" ] && {
      echo "  [warn] skipping invalid line: $line"
      continue
    }
    conf_roles="${conf_roles:-$ROLES}"
    conf_project_root="${GLOBAL_PROJECTS_DIR}/${conf_project}"

    if [ -n "$conf_repos" ]; then
      "${SCRIPT_DIR}/setup-multi.sh" "$conf_project_root" "$conf_init" "$conf_branch" \
        --repos "$conf_repos" --roles "$conf_roles" \
        $([ "$PING_INTERVAL" = "0" ] && echo "--no-ping")
    else
      PROJECT_ROOT="$conf_project_root"
      PROJECT_NAME=$(basename "$PROJECT_ROOT")
      PROJECT_TEMPLATES_DIR="$PROJECT_ROOT/.kiro/agent-templates"
      SESSION_PREFIX="kiro-${PROJECT_NAME}"
      setup_one "$conf_init" "$conf_branch" "$conf_roles" "$PING_INTERVAL"
    fi
    count=$((count + 1))
  done < "$CONF"

  if [ "$count" -eq 0 ]; then
    echo ""
    echo "Warning: no initiatives found in $CONF"
  fi
else
  setup_one "$INITIATIVE" "$BRANCH" "$ROLES" "$PING_INTERVAL"
fi

# ---- Done ----
echo ""
echo "=== Setup complete ==="
echo "Attach:"
echo "  tmux attach -t kiro-chief"
if [ "$ALL_MODE" -eq 0 ]; then
  echo "  tmux attach -t ${SESSION_PREFIX}-${INITIATIVE}"
else
  for sess in $(tmux list-sessions -F "#{session_name}" 2>/dev/null | grep "^${SESSION_PREFIX}-" || true); do
    echo "  tmux attach -t $sess"
  done
fi


