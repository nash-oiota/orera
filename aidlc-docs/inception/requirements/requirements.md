# Requirements Document — kiro-team

## Intent Analysis

- **User Request**: tmux と kiro-cli を使ったマルチエージェント開発チームツールの構築
- **Request Type**: New Project（Greenfield）
- **Scope**: 複数コンポーネント（scripts, agent configs, watcher）
- **Complexity**: Moderate

---

## Functional Requirements

### FR-01: チーム起動
- `start.sh` を実行すると PdM セッションと watcher.sh が起動する
- PdM セッションは `kiro-cli chat --agent pdm` で起動する
- ユーザーは起動後 PdM セッションにアタッチされる

### FR-02: スペシャリストの動的管理
- PdM はタスク委任時に対象 specialist の tmux セッションが存在するか確認する
- セッションが存在しない場合、PdM が `execute_bash` で新規作成して `kiro-cli chat --agent <name>` を起動する
- セッション起動後、kiro-cli の初期化を待つ sleep を挟んでから委任する
- セッションが存在する場合はそのまま委任する

### FR-03: タスク委任
- PdM は `tasks/<agent-name>.md` にタスク内容を書き込む
- send-keys は直接使わない（タイミング制御は notifier.sh に委譲）
- 指示フォーマットは PdM のシステムプロンプトに定義する

### FR-03b: タスク配送（notifier.sh）
- `notifier.sh` が常時 `tasks/` を監視する
- 新規タスクファイルを検知したら、対象 specialist セッションの `tmux capture-pane` でプロンプト待ち状態を確認する
- プロンプト待ち確認後に `tmux send-keys` でタスクを送信する
- 送信済みマーク（`tasks/<name>.sent`）を作成し、重複送信を防ぐ

### FR-04: 結果報告
- specialist は完了後に `results/<agent-name>.md` に結果を書き込む

### FR-05: 完了通知
- `watcher.sh` が常時 `results/` を監視する
- 新規・更新ファイルを検知したら `tmux send-keys -t kiro-team:pdm "[SYSTEM] <name> completed." Enter` で PdM に通知する

### FR-05b: results ファイルフォーマット
specialist は `results/<agent-name>.md` に以下のフォーマットで書き込む：

```
STATUS: QUESTION | BLOCKED | COMPLETE
---
（内容）
```

| STATUS | 意味 | PdM のアクション |
|---|---|---|
| QUESTION | 質問あり、回答待ち | 自律回答 or ユーザーにエスカレーション |
| BLOCKED | 外部要因で進めない | ユーザーに報告 |
| COMPLETE | 完了 | 次のアクションへ |

### FR-11: レビューフロー
- frontend と backend の両方が `STATUS: COMPLETE` になったら、PdM が `reviewer` に結合レビューを依頼する
- reviewer は `STATUS: APPROVED` または `STATUS: CHANGES_REQUESTED` で結果を返す
- `CHANGES_REQUESTED` の場合、PdM が該当 specialist に修正タスクを振り直し、再レビューを依頼する
- `APPROVED` になったら qa にテストを依頼する
- ユーザーへの最終報告は qa のテスト完了後に行う

### FR-12: results ファイルの STATUS 拡張
- `STATUS: APPROVED` — reviewer が結合レビューを承認
- `STATUS: CHANGES_REQUESTED` — reviewer が修正を要求（ISSUE-XX 形式で課題を列挙）
- PdM はユーザー承認が不要な判断（次の specialist への委任、結果の統合など）を自律的に実行する
- ユーザー確認が必要な場合のみ質問する

### FR-07: チーム停止
- `stop.sh` を実行すると全 tmux セッションを停止する

### FR-08: ステータス確認
- `status.sh` を実行すると全エージェントのセッション生死と `results/*.md` の最終更新時刻を表示する
- PdM も `execute_bash` 経由で `status.sh` を利用できる

### FR-09: チーム構成
- デフォルトスペシャリスト：frontend / backend / infra / qa
- チーム構成は `.kiro/agents/*.json` ファイルで定義する（ファイル追加 = メンバー追加）

### FR-10: PdM エージェント定義
- PdM のシステムプロンプトには以下を含む：
  - 役割（PdM + TL的マネジメント）
  - タスク分解ガイドライン
  - 各スペシャリストの専門領域
  - specialist への命令フォーマット
  - 自律判断ガイドライン（何をユーザーに確認し、何を自律実行するか）

---

## Non-Functional Requirements

### NFR-01: 依存関係の最小化
- MVP は Bash + tmux + kiro-cli のみ。Python・外部メッセージキュー・fswatch 等は使用しない

### NFR-02: macOS / Linux 互換
- Bash 3.2+ で動作すること

### NFR-03: ローカル専用
- ネットワーク露出なし。kiro-cli の認証は kiro-cli 自身が管理する

### NFR-04: セキュリティ
- スクリプトやエージェント設定にシークレット・APIキーをハードコードしない
- Security Baseline 拡張ルール（SECURITY-01〜15）を適用する

---

## 実装上の注意点

- **通知の対応関係**: watcher.sh の通知メッセージにはエージェント名とファイルパスを含める（例: `[SYSTEM] backend-1 updated results. Check results/backend-1.md`）。PdM が複数エージェントからの通知を混同しないようにする。
- **通知の順序制御**: watcher.sh は「未通知の変更があるか」と「PdM がプロンプト待ちか」の両方を確認してから send-keys する。PdM が処理中の場合はスキップし次のポーリングで再試行する。通知済みマーク（results/<name>.notified）で重複通知を防ぐ。
- **エージェント権限の事前承認**: `allowedTools` に必要なツールをすべて列挙し、実行中のユーザー確認を防ぐ。初期実装では必要な権限を網羅し、運用しながら絞っていく方針とする。

  | エージェント | allowedTools |
  |---|---|
  | PdM | `execute_bash`, `fs_write`, `fs_read` |
  | specialist（全員） | `execute_bash`, `fs_write`, `fs_read` |

**: JSON の `name` フィールド・ファイル名・tmux セッション名・tasks/results のファイル名はすべて一致させる。`start.sh` 起動時に `name` フィールドとファイル名の一致を検証するチェックを入れること。
- **PdM セッション名のハードコード回避**: watcher.sh の通知先（`kiro-team:pdm`）は PdM の JSON `name` フィールドから動的に取得する。ハードコードしない。
- **tasks/ と results/ のファイル名生成ロジックの一元化**: notifier.sh と watcher.sh でファイル名生成ロジックを重複させない。共通の命名規則を1箇所で定義する。

## Open Questions（実装前に確認が必要）

- `kiro-cli chat --agent <name>` フラグの動作確認（未検証）
- kiro-cli の起動完了を検知する確実な方法（sleep の秒数調整が必要な可能性）
- kiro-cli の長時間稼働時のコンテキスト肥大化への対処

---

## Project Structure

```
kiro-team/
├── scripts/
│   ├── start.sh        # PdM + watcher + notifier 起動
│   ├── stop.sh         # 全セッション停止
│   ├── status.sh       # セッション状態確認
│   ├── watcher.sh      # results/ 常時監視・PdM 通知
│   └── notifier.sh     # tasks/ 常時監視・specialist へ配送
├── .kiro/
│   └── agents/
│       ├── pdm.json
│       ├── frontend.json
│       ├── backend.json
│       ├── infra.json
│       └── qa.json
├── tasks/
├── results/
└── README.md
```
