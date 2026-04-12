# NFR Design Patterns — Unit 1: scripts

## Fail-Fast パターン（エラー処理）

致命的エラー（tmux 未インストール、kiro-cli 未インストール）は即終了。
非致命的エラー（特定エージェントへの send-keys 失敗）は stderr に出力してスキップ。

```bash
# 致命的エラー
command -v tmux >/dev/null 2>&1 || { echo "Error: tmux not found" >&2; exit 1; }

# 非致命的エラー（notifier.sh）
tmux send-keys ... || { echo "Warning: failed to send to $agent" >&2; continue; }
```

## ポーリングループパターン（watcher.sh / notifier.sh）

設定可能な間隔で繰り返し監視。リトライロジック不要（次のループで自動再試行）。

```bash
while true; do
  # 処理
  sleep "$POLL_INTERVAL"
done
```

## 入力値検証パターン（start.sh）

エージェント名を tmux ウィンドウ名・ファイルパスに使う前に正規表現で検証。

```bash
validate_agent_name() {
  [[ "$1" =~ ^[a-zA-Z0-9_-]+$ ]] || { echo "Error: invalid agent name: $1" >&2; exit 1; }
}
```

## 設定集約パターン（config.sh）

全スクリプトが `source scripts/config.sh` で共通設定を読み込む。変更箇所を1ファイルに集約。

## タイムアウト付き待機パターン（wait_for_prompt）

capture-pane でプロンプト確認。PROMPT_TIMEOUT 秒以内に検知できなければ失敗を返す。

```bash
wait_for_prompt() {
  local elapsed=0
  while [ $elapsed -lt "$PROMPT_TIMEOUT" ]; do
    tmux capture-pane -t "$SESSION_NAME:$1" -p | tail -1 | grep -q "$PROMPT_PATTERN" && return 0
    sleep 1; elapsed=$((elapsed + 1))
  done
  return 1
}
```
