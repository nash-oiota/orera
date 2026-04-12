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
mkdir -p "$TARGET/.kiro/agents"

cp "$SCRIPT_DIR"/*.sh "$TARGET/kiro-team/scripts/"
cp "$SOURCE_DIR/.kiro/agents"/kiro-team-*.json "$TARGET/.kiro/agents/"

echo "✅ Installed to $TARGET"
echo ""
echo "Run from $TARGET:"
echo "  ./kiro-team/scripts/start.sh"
