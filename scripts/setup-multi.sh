#!/bin/bash
# setup-multi.sh - 複数リポジトリを横断する案件のセットアップ
#
# 各リポジトリに feature/<branch> worktree を作成し、
# メタディレクトリ (<project>-<initiative>/) にシンボリックリンクをまとめる。
#
# Usage:
#   setup-multi.sh [project-root] <initiative> <branch> --repos repo1,repo2,... [options]
#
# Options:
#   --repos <list>   横断するリポジトリ名 (~/projects/ 配下のディレクトリ名)
#   --roles <list>   使用するロール (default: pdm,frontend,backend,qa,reviewer)
#   --no-ping        定期自律ping を無効化
#
# Example:
#   setup-multi.sh ~/projects/your-modernization modernization mod-main \
#     --repos your-app,your-deploy --roles pdm,backend,infra,qa,reviewer

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KIRO_TEAM_DIR="$(dirname "$SCRIPT_DIR")"
GENERIC_TEMPLATES_DIR="$KIRO_TEAM_DIR/agents/templates"

usage() {
  cat <<USAGE
Usage:
  $0 [project-root] <initiative> <branch> --repos repo1,repo2,... [options]

Options:
  --repos <list>   横断するリポジトリ名 (project-root の親ディレクトリ配下)
  --roles <list>   ロール (default: pdm,frontend,backend,qa,reviewer)
  --no-ping        定期自律ping を無効化
USAGE
}

resolve_project_root() {
  if [ "$#" -gt 0 ] && [ -d "$1" ]; then
    echo "$1"; return 0
  fi
  if git rev-parse --show-toplevel >/dev/null 2>&1; then
    git rev-parse --show-toplevel; return 0
  fi
  pwd
}

# ---- Argument parsing ----
PROJECT_ROOT=""
REPOS=""
ROLES="pdm,frontend,backend,qa,reviewer"
PING_INTERVAL=1800

if [ "$#" -gt 0 ] && [ -d "$1" ]; then
  PROJECT_ROOT="$1"; shift
fi

POSITIONAL=()
while [ "$#" -gt 0 ]; do
  case "$1" in
    --repos)  REPOS="$2";         shift 2 ;;
    --roles)  ROLES="$2";         shift 2 ;;
    --no-ping) PING_INTERVAL=0;   shift   ;;
    -h|--help) usage; exit 0      ;;
    -*) echo "Unknown option: $1"; usage; exit 1 ;;
    *)  POSITIONAL+=("$1");       shift   ;;
  esac
done

if [ -z "$PROJECT_ROOT" ]; then
  PROJECT_ROOT="$(resolve_project_root)"
fi

if [ "${#POSITIONAL[@]}" -lt 2 ]; then
  echo "Error: <initiative> and <branch> required"
  usage; exit 1
fi
if [ -z "$REPOS" ]; then
  echo "Error: --repos is required"
  usage; exit 1
fi

INITIATIVE="${POSITIONAL[0]}"
BRANCH="${POSITIONAL[1]}"
PROJECT_NAME=$(basename "$PROJECT_ROOT")
PROJECTS_DIR="$(dirname "$PROJECT_ROOT")"
PROJECT_TEMPLATES_DIR="$PROJECT_ROOT/.kiro/agent-templates"
SESSION_PREFIX="kiro-${PROJECT_NAME}"
CHIEF_SESSION="kiro-chief"
CHIEF_AGENTS_DIR="${HOME}/.kiro/agents"

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

start_chief_if_needed() {
  if tmux has-session -t "$CHIEF_SESSION" 2>/dev/null; then
    echo "  [skip] $CHIEF_SESSION already running"; return 0
  fi
  mkdir -p "$CHIEF_AGENTS_DIR"
  if [ ! -f "${CHIEF_AGENTS_DIR}/chief-pdm.json" ]; then
    local chief_template="$GENERIC_TEMPLATES_DIR/chief-pdm.json"
    sed "s/{project}/global/g" "$chief_template" > "${CHIEF_AGENTS_DIR}/chief-pdm.json"
    echo "  [created] ${CHIEF_AGENTS_DIR}/chief-pdm.json"
  fi
  tmux new-session -d -s "$CHIEF_SESSION" -c "$PROJECTS_DIR"
  tmux send-keys -t "$CHIEF_SESSION" "kiro-cli chat --agent chief-pdm" Enter
  local chief_log="${HOME}/.kiro/chief-notifier.log"
  nohup "${SCRIPT_DIR}/chief-notifier.sh" "$PROJECTS_DIR" > "$chief_log" 2>&1 &
  echo "  [started] $CHIEF_SESSION (chief-pdm + chief-notifier) @ $PROJECTS_DIR"
}

# ---- Header ----
echo "=== Project: $PROJECT_NAME ($PROJECT_ROOT) ==="
echo "=== Mode: multi-repo ==="
echo ""
echo "=== Chief session ==="
start_chief_if_needed
echo ""
echo "=========================================="
echo "  Initiative: $INITIATIVE"
echo "  Branch:     feature/${BRANCH}"
echo "  Repos:      $REPOS"
echo "  Meta dir:   $META_DIR"
echo "  Roles:      $ROLES"
echo "  Ping:       $([ "$PING_INTERVAL" = "0" ] && echo disabled || echo "${PING_INTERVAL}s")"
echo "=========================================="

# ---- 0. Pre-flight: verify all repos exist ----
IFS=',' read -ra repo_arr <<< "$REPOS"
for repo in "${repo_arr[@]}"; do
  repo_dir="${PROJECTS_DIR}/${repo}"
  if [ ! -d "$repo_dir" ]; then
    echo "  [error] repo not found: $repo_dir"
    exit 1
  fi
done
echo "  [ok] all repos found"

# ---- 1. Create worktree in each repo ----
IFS=',' read -ra repo_arr <<< "$REPOS"
for repo in "${repo_arr[@]}"; do
  repo_dir="${PROJECTS_DIR}/${repo}"
  worktree_dir="${PROJECT_ROOT}/${repo}-${INITIATIVE}"
  if [ -d "$worktree_dir" ]; then
    echo "  [skip worktree] $worktree_dir already exists"
  else
    cd "$repo_dir"
    if ! git show-ref --verify --quiet "refs/heads/feature/${BRANCH}"; then
      local_base=$(git rev-parse --abbrev-ref HEAD)
      git branch "feature/${BRANCH}" "$local_base"
      echo "  [branch created] feature/${BRANCH} in $repo (from $local_base)"
    fi
    git worktree add "$worktree_dir" "feature/${BRANCH}"
    echo "  [worktree created] $worktree_dir"
  fi
done

# ---- 2. Tasks / results / plans dirs ----
tasks_dir="${PROJECT_ROOT}/kiro-team/teams/${INITIATIVE}/tasks"
results_dir="${PROJECT_ROOT}/kiro-team/teams/${INITIATIVE}/results"
plans_dir="${PROJECT_ROOT}/kiro-team/teams/${INITIATIVE}/plans"
mkdir -p "$tasks_dir" "$results_dir" "$plans_dir"

# ---- 3. Agent definitions ----
agents_dir="${PROJECT_ROOT}/.kiro/agents"
mkdir -p "$agents_dir"
IFS=',' read -ra role_arr <<< "$ROLES"
for role in "${role_arr[@]}"; do
  template=""
  if ! template=$(resolve_template "$role"); then
    echo "  [error] template not found for role: $role"
    echo "         Searched: $PROJECT_TEMPLATES_DIR, $GENERIC_TEMPLATES_DIR"
    exit 1
  fi
  target="${agents_dir}/${INITIATIVE}-${role}.json"
  if [ -f "$target" ]; then
    echo "  [skip agent] ${INITIATIVE}-${role}.json"
  else
    sed "s/{team}/${INITIATIVE}/g" "$template" > "$target"
    echo "  [agent created] ${INITIATIVE}-${role}.json"
  fi
done

# ---- 4. Session ----
session_name="${SESSION_PREFIX}-${INITIATIVE}"
if tmux has-session -t "$session_name" 2>/dev/null; then
  echo "  [skip session] $session_name already running"
else
  tmux new-session -d -s "$session_name" -c "$PROJECT_ROOT"
  pdm_pane=$(tmux list-panes -t "$session_name" -F "#{pane_id}" | head -1)
  echo "$pdm_pane" > "${tasks_dir}/.pane_${INITIATIVE}-pdm"
  tmux send-keys -t "$session_name" "kiro-cli chat --agent ${INITIATIVE}-pdm" Enter

  notifier_log="${tasks_dir}/.notifier.log"
  nohup "${SCRIPT_DIR}/team-notifier.sh" "$INITIATIVE" "$PROJECT_ROOT" "$PING_INTERVAL" \
    > "$notifier_log" 2>&1 &
  echo "  [session started] $session_name (log: $notifier_log)"
fi

echo ""
echo "=== Setup complete ==="
echo "Repos available in session:"
for repo in "${repo_arr[@]}"; do
  echo "  $PROJECT_ROOT/${repo}-${INITIATIVE}/"
done
echo "Attach:"
echo "  tmux attach -t kiro-chief"
echo "  tmux attach -t $session_name"

