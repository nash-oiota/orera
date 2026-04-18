#!/bin/bash
# install.sh - kiro-team を指定プロジェクトにインストールする
# Usage:
#   ./scripts/install.sh /path/to/project

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="$(dirname "$SCRIPT_DIR")"
TARGET="${1:?Usage: install.sh /path/to/project}"

echo "Installing kiro-team to $TARGET ..."

mkdir -p "$TARGET/kiro-team/scripts"
mkdir -p "$TARGET/kiro-team/plans"
mkdir -p "$TARGET/.kiro/agents"
mkdir -p "$TARGET/.kiro/steering"

cp "$SCRIPT_DIR"/*.sh "$TARGET/kiro-team/scripts/"
cp "$SOURCE_DIR/.kiro/agents"/kiro-team-*.json "$TARGET/.kiro/agents/"
cp "$SOURCE_DIR"/plans/TEMPLATE.md "$SOURCE_DIR"/plans/PROPOSAL_TEMPLATE.md "$TARGET/kiro-team/plans/"
cp "$SOURCE_DIR"/steering/*.md "$TARGET/.kiro/steering/"

echo "✅ Installed to $TARGET"
echo ""
echo "Run from $TARGET:"
echo "  ./kiro-team/scripts/start.sh"
