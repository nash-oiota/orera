# NFR Requirements — Unit 1: scripts

## 信頼性

- **エラー処理**: エラー発生時は stderr にメッセージを出力して exit 1 で終了する
- **タイムアウト**: `wait_for_prompt()` のタイムアウトはデフォルト 10 秒（`PROMPT_TIMEOUT` として config.sh で設定可能）
- **前提条件チェック**: start.sh 起動時に tmux・kiro-cli の存在を確認し、未インストールの場合は即終了

## パフォーマンス

- **ポーリング間隔**: デフォルト 5 秒（`POLL_INTERVAL` として config.sh で設定可能）
- **起動待ち**: kiro-cli 起動後の初期待機はデフォルト 10 秒（`STARTUP_WAIT` として config.sh で設定可能）

## ロギング

- ファイルログなし
- watcher.sh / notifier.sh の出力は tmux ウィンドウ内で確認する
- エラーは stderr に出力

## セキュリティ（Security Baseline 適用）

| ルール | 適用 | 対応 |
|---|---|---|
| SECURITY-05 | ✅ | エージェント名・ファイルパスの入力値検証（英数字・ハイフンのみ許可） |
| SECURITY-06 | ✅ | allowedTools で最小権限を設定（agent-configs で対応） |
| SECURITY-09 | ✅ | スクリプトにシークレット・APIキーをハードコードしない |
| SECURITY-11 | ✅ | 設定（config.sh）・起動（start.sh）・監視（watcher/notifier）の責務分離 |
| SECURITY-15 | ✅ | 全外部コマンド（tmux, kiro-cli）に明示的なエラーハンドリングを実装 |
| SECURITY-01,02,03,04,07,08,10,12,13,14 | N/A | ローカルツール・ネットワーク露出なし・認証不要 |

## 保守性

- config.sh に設定値を集約し、変更箇所を最小化する
- 各スクリプトは単一責務を持つ
