# Code Summary — Unit 1: scripts

## 生成ファイル

| ファイル | 説明 |
|---|---|
| scripts/config.sh | 共通設定（SESSION_NAME, POLL_INTERVAL, PROMPT_TIMEOUT 等） |
| scripts/start.sh | 前提条件チェック・エージェント名検証・PdM+watcher+notifier 起動 |
| scripts/stop.sh | tmux セッション停止 |
| scripts/status.sh | セッション生死 + results/ STATUS 表示 |
| scripts/watcher.sh | results/ ポーリング・PdM プロンプト確認・通知送信 |
| scripts/notifier.sh | tasks/ ポーリング・specialist プロンプト確認・タスク配送 |
| README.md | 使い方・設定・デバッグガイド |

## 実装パターン

- Fail-Fast: 致命的エラーは exit 1、非致命的は stderr + continue
- ポーリングループ: while true + sleep $POLL_INTERVAL
- 入力値検証: `^[a-zA-Z0-9_-]+$` 正規表現
- タイムアウト付き待機: PROMPT_TIMEOUT 秒でタイムアウト
