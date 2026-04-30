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

# ---- Project shim: setup-multi.sh ----
cat > "$TARGET/kiro-team/scripts/setup-multi.sh" <<'SHIM'
#!/bin/bash
# Thin shim — calls ~/kiro-team/scripts/setup-multi.sh with project root auto-resolved.
set -e
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
KIRO_TEAM_HOME="${KIRO_TEAM_HOME:-$HOME/kiro-team}"
exec "${KIRO_TEAM_HOME}/scripts/setup-multi.sh" "$PROJECT_ROOT" "$@"
SHIM
chmod +x "$TARGET/kiro-team/scripts/setup-multi.sh"
echo "  [created] kiro-team/scripts/setup-multi.sh"

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

# 横断リポジトリ案件
./kiro-team/scripts/setup-multi.sh <initiative> <branch> --repos repo1,repo2 [--roles ...]

# ~/kiro-team/projects.conf に書いた全案件を立ち上げ
~/kiro-team/scripts/setup-teams.sh --all

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
echo "  1. Add to ~/kiro-team/projects.conf:"
echo "     ${TARGET##*/}:<initiative>:<branch>:<roles>"
echo "  2. ~/kiro-team/scripts/setup-teams.sh --all"
echo "     or"
echo "     ./kiro-team/scripts/setup.sh <initiative> <branch>  # 個別起動"


