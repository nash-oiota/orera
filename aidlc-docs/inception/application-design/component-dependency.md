# Component Dependencies — kiro-team

## 依存関係マトリクス

| コンポーネント | 依存先 | 通信方式 |
|---|---|---|
| start.sh | config.sh | source |
| stop.sh | config.sh | source |
| status.sh | config.sh | source |
| watcher.sh | config.sh | source |
| notifier.sh | config.sh | source |
| PdM（kiro-cli） | tasks/（書き込み）, results/（読み取り）, status.sh | execute_bash |
| specialist（kiro-cli） | results/（書き込み）, tasks/（読み取り） | fs_write / fs_read |
| watcher.sh | results/（読み取り）, PdM セッション | ファイル監視 / tmux send-keys / capture-pane |
| notifier.sh | tasks/（読み取り）, specialist セッション | ファイル監視 / tmux send-keys / capture-pane |

## データフロー

```
ユーザー
  |
  | チャット
  v
PdM（kiro-cli: pdm）
  |
  | fs_write
  v
tasks/<agent-name>.md
  |
  | ファイル監視
  v
notifier.sh
  |
  | capture-pane（プロンプト確認）
  | tmux send-keys
  v
specialist（kiro-cli: <name>）
  |
  | fs_write
  v
results/<agent-name>.md
  |
  | ファイル監視
  v
watcher.sh
  |
  | capture-pane（PdM プロンプト確認）
  | tmux send-keys（未通知かつ待機中のみ）
  v
PdM（kiro-cli: pdm）
  |
  | 自律判断 or ユーザーへ確認
  v
ユーザー
```

## 命名規約（一貫性保証）

- エージェント識別子 = `.kiro/agents/<name>.json` の `name` フィールド = ファイル名（拡張子除く）
- tmux ウィンドウ名 = エージェント識別子
- tasks/<name>.md = エージェント識別子
- results/<name>.md = エージェント識別子
- start.sh 起動時に JSON `name` フィールドとファイル名の一致を検証する
