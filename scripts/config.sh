#!/bin/bash
# config.sh - kiro-team 共通設定
# 全スクリプトが source scripts/config.sh で読み込む

SESSION_NAME="kiro-$(basename "$PWD")"  # プロジェクトごとに独立したセッション
AGENTS_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")/.kiro/agents"  # プロジェクトルート/.kiro/agents/
TASKS_DIR="kiro-team/tasks"
RESULTS_DIR="kiro-team/results"
POLL_INTERVAL=5          # ポーリング間隔（秒）
STARTUP_WAIT=5           # kiro-cli 起動待ち（秒）
PROMPT_TIMEOUT=60        # wait_for_prompt タイムアウト（秒）
PROMPT_PATTERN="% > *$"  # kiro-cli プロンプト検知パターン（例: [backend] 0% >）
LOG_DIR="kiro-team/logs"
