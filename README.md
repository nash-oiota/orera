# kiro-team

tmux + kiro-cli を使ったマルチエージェント開発チームツール。PdM に指示するだけで、frontend / backend / infra / qa の specialist が自律的に動く。

## 必要なもの

- tmux
- kiro-cli

## インストール（グローバル利用）

任意のプロジェクトから使えるようにするには：

```bash
./scripts/install.sh
```

`~/.zshrc` または `~/.bashrc` に追加：

```bash
export PATH="$HOME/kiro-team/scripts:$PATH"
```

以降は任意のプロジェクトディレクトリで：

```bash
cd ~/my-project
start.sh
```

`tasks/` と `results/` はプロジェクトディレクトリに作られます。エージェント設定は `~/kiro-team/.kiro/agents/` を参照します。

エージェントをカスタマイズする場合は `~/kiro-team/.kiro/agents/` を編集してください。

## 使い方

```bash
# チーム起動（PdM セッションにアタッチされる）
./scripts/start.sh

# チーム停止
./scripts/stop.sh            # 通常停止（tasks/results はそのまま）
./scripts/stop.sh --archive  # アーカイブして停止（別タスクに切り替える時）
./scripts/stop.sh --clean    # 削除して停止（完全リセット）

# 状態確認
./scripts/status.sh
```

## チーム構成

| エージェント | 役割 |
|---|---|
| pdm | PdM + TL。ユーザーと会話し、specialist に委任 |
| frontend | UI/UX 実装 |
| backend | API・ビジネスロジック実装 |
| infra | デプロイ・環境構成 |
| qa | テスト・品質管理 |

## カスタマイズ

`.kiro/agents/` に JSON ファイルを追加するだけでチームメンバーを増やせる。

```json
{
  "name": "designer",
  "prompt": "You are a UI Designer...",
  "tools": ["fs_write", "fs_read"],
  "allowedTools": ["fs_write", "fs_read"]
}
```

**注意**: `name` フィールドはファイル名（拡張子除く）と一致させること。

## 動作確認手順

### クリーンスタート

```bash
tmux kill-server
rm -rf backend frontend qa
rm -f tasks/*.md tasks/*.sent tasks/.pane_* tasks/.specialist_pane tasks/.pdm_pane
rm -f results/*.md results/*.notified results/*.mtime
./scripts/start.sh
```

### PdM への命令例

```
シンプルなメモアプリを作ってください。backendはNode.jsでREST API、frontendはHTML/CSS/JSでUI、qaはテストシナリオを作成してください。
```

### 確認ポイント

| 確認内容 | コマンド |
|---|---|
| タスク配送状況 | `ls tasks/` |
| 結果状況 | `ls results/` |
| セッション状態 | `./scripts/status.sh` |
| PdM の状態 | `Ctrl+b 0` |
| specialist の状態 | `Ctrl+b w` でウィンドウ選択 |
| watcher ログ | `Ctrl+b 1` |
| notifier ログ | `Ctrl+b 2` |

### 正常動作の流れ

1. PdM が `tasks/<agent>.md` を書く
2. notifier が検知 → specialist セッション起動 → タスク送信（`<agent>.sent` 作成）
3. specialist が `results/<agent>.md` に書く（`STATUS: COMPLETE`）
4. watcher が検知 → PdM に `[SYSTEM]` 通知
5. PdM が結果を読んで次のアクション or ユーザーに報告

### 既知の制約

- specialist が長時間プロセス（`node server.js` 等）を起動するとブロックされる
- kiro-cli のコンテキストが長くなると応答が遅くなる
- 再起動時、未送信タスクは自動再開される（意図した動作）

## 再起動時の動作

`start.sh` 再起動時、`tasks/` に未送信（`.sent` マークなし）のタスクが残っていれば自動的に再送します。これは前回の未完了タスクの再開として意図した動作です。

完全にリセットしたい場合：
```bash
tmux kill-server
rm -f tasks/*.md tasks/*.sent results/*.md results/*.notified results/*.mtime
./scripts/start.sh
```

## デバッグ

```bash
# specialist の作業を覗く
Ctrl+b w  # ウィンドウ一覧から選択
Ctrl+b n  # 次のウィンドウへ
```

## 設定変更

`scripts/config.sh` で以下を変更できる：

| 変数 | デフォルト | 説明 |
|---|---|---|
| POLL_INTERVAL | 5 | ポーリング間隔（秒） |
| STARTUP_WAIT | 10 | kiro-cli 起動待ち（秒） |
| PROMPT_TIMEOUT | 30 | プロンプト待ちタイムアウト（秒） |
| PROMPT_PATTERN | `^>` | kiro-cli プロンプト検知パターン |
