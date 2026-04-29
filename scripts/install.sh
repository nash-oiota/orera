#!/bin/bash
# install.sh - kiro-team を指定プロジェクトにインストール (薄いシムを生成)
#
# 設計:
#   ~/kiro-team はライブラリ (単一ソース)。プロジェクト側はシム + 設定のみ持つ。
#   ~/kiro-team を更新するだけで全プロジェクトに反映される。
#
# Usage:
#   ./install.sh <project-root>
# Example:
#   ~/kiro-team/scripts/install.sh ~/Desktop/projects/myproject

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KIRO_TEAM_DIR="$(dirname "$SCRIPT_DIR")"
TARGET="${1:?Usage: $0 <project-root>}"

if [ ! -d "$TARGET" ]; then
  echo "Error: $TARGET does not exist"
  exit 1
fi

echo "Installing kiro-team into: $TARGET"
echo "Library source: $KIRO_TEAM_DIR"
echo ""

# ---- Directory structure ----
mkdir -p "$TARGET/kiro-team/scripts"
mkdir -p "$TARGET/kiro-team/plans"
mkdir -p "$TARGET/kiro-team/teams"
mkdir -p "$TARGET/.kiro/agents"
mkdir -p "$TARGET/.kiro/agent-templates"

# ---- Project shim: setup.sh ----
cat > "$TARGET/kiro-team/scripts/setup.sh" <<'SHIM'
#!/bin/bash
# Thin shim — calls ~/kiro-team/scripts/setup-teams.sh with project root auto-resolved.
# Override library location with KIRO_TEAM_HOME env var if needed.
set -e
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
KIRO_TEAM_HOME="${KIRO_TEAM_HOME:-$HOME/kiro-team}"
exec "${KIRO_TEAM_HOME}/scripts/setup-teams.sh" "$PROJECT_ROOT" "$@"
SHIM
chmod +x "$TARGET/kiro-team/scripts/setup.sh"
echo "  [created] kiro-team/scripts/setup.sh"

# ---- Project shim: stop.sh ----
cat > "$TARGET/kiro-team/scripts/stop.sh" <<'SHIM'
#!/bin/bash
# Thin shim — calls ~/kiro-team/scripts/stop-teams.sh with project root auto-resolved.
set -e
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
KIRO_TEAM_HOME="${KIRO_TEAM_HOME:-$HOME/kiro-team}"
exec "${KIRO_TEAM_HOME}/scripts/stop-teams.sh" "$PROJECT_ROOT" "$@"
SHIM
chmod +x "$TARGET/kiro-team/scripts/stop.sh"
echo "  [created] kiro-team/scripts/stop.sh"

# ---- teams.conf.example ----
if [ ! -f "$TARGET/kiro-team/teams.conf" ]; then
  cat > "$TARGET/kiro-team/teams.conf.example" <<'CONF'
# teams.conf - プロジェクト配下の案件 (initiative) 定義
#
# フォーマット: <initiative>:<branch>[:<roles>]
#   - initiative: 案件名 (worktree とセッション名の suffix)
#   - branch: feature/<branch> 形式で worktree 作成
#   - roles (任意): カンマ区切り。省略時は pdm,frontend,backend,qa,reviewer
#
# 立ち上げ:
#   ./kiro-team/scripts/setup.sh --all          # 配下を全て起動
#   ./kiro-team/scripts/setup.sh <init> <br>    # 個別起動
#
# 例:
# blog:content-main:pdm,frontend,qa,reviewer
# growth:growth-main:pdm,frontend,qa,reviewer,designer
# api-rewrite:api-rewrite-main:pdm,backend,qa,reviewer,architect
CONF
  echo "  [created] kiro-team/teams.conf.example (rename to teams.conf to use --all)"
fi

# ---- .gitkeep for empty dirs ----
touch "$TARGET/kiro-team/plans/.gitkeep"
touch "$TARGET/kiro-team/teams/.gitkeep"
touch "$TARGET/.kiro/agents/.gitkeep"
touch "$TARGET/.kiro/agent-templates/.gitkeep"

# ---- README hint ----
cat > "$TARGET/kiro-team/README.md" <<README
# kiro-team (this project)

This project uses [kiro-team](file://${KIRO_TEAM_DIR}) as its multi-agent autonomous development library.

## Structure

\`\`\`
kiro-team/
├── scripts/
│   ├── setup.sh        # 案件立ち上げ (~/kiro-team/scripts/setup-teams.sh への shim)
│   └── stop.sh         # 案件停止
├── plans/              # 施策の plan ファイル
├── teams/<initiative>/ # 案件ごとの tasks/, results/, plans/
└── teams.conf          # --all 用の案件定義 (任意)

.kiro/
├── agents/             # 案件ごとに自動生成される PdM/specialist 定義
└── agent-templates/    # プロジェクト固有のテンプレ override (任意)
\`\`\`

## Quick start

\`\`\`bash
# 案件1つ立ち上げ
./kiro-team/scripts/setup.sh <initiative> <branch> [--roles ...] [--no-ping]

# teams.conf に書いた全案件を立ち上げ
cp kiro-team/teams.conf.example kiro-team/teams.conf  # 編集
./kiro-team/scripts/setup.sh --all

# 全停止
./kiro-team/scripts/stop.sh
\`\`\`

## Project-specific roles

\`.kiro/agent-templates/team-<role>.json\` を置くと、汎用テンプレより優先して使われます。
プロジェクト固有のロール (例: educator, marketer) はここに置いてください。
README

echo "  [created] kiro-team/README.md"

echo ""
echo "✅ Installed."
echo ""
echo "Next steps:"
echo "  1. cd $TARGET"
echo "  2. (optional) cp kiro-team/teams.conf.example kiro-team/teams.conf && \$EDITOR kiro-team/teams.conf"
echo "  3. ./kiro-team/scripts/setup.sh <initiative> <branch>      # 個別案件起動"
echo "     or"
echo "     ./kiro-team/scripts/setup.sh --all                       # teams.conf 全起動"
