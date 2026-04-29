# kiro-team

tmux + kiro-cli で動く「**案件 (initiative) ごとの自律エージェントチーム**」フレームワーク。
1案件 = 1 worktree = 1 tmux セッション = 1 チーム (PdM + specialists) で並列実行する。

## コンセプト

- **案件単位の独立**: 1案件1 worktree。同一リポで複数案件を干渉なく並走できる
- **階層構造**: chief-pdm が複数の案件 PdM を統括、案件 PdM が specialists を率いる
- **ファイルベース通信**: tasks/<role>.md → results/<role>.md でタスク配送と結果回収
- **自律運用 (任意)**: 30分間隔の ping で PdM を自発的に駆動 (`--no-ping` で無効化可能)
- **テンプレ駆動**: 13個の汎用ロールテンプレを `{team}` プレースホルダーで案件名に展開

## 必要なもの

- tmux
- kiro-cli
- git (worktree 対応)
- Node.js (プロジェクトが Node の場合)

## 提供するロールテンプレ

`agents/templates/` に汎用テンプレを用意。`{team}` を案件名で置換して各案件のエージェント定義を生成する。

### コア (`--roles` 既定)
| ロール | 役割 |
|---|---|
| **pdm** | 案件司令塔。タスク分解・委譲・統合 |
| **frontend** | UI/クライアント実装 |
| **backend** | API/サーバー実装 |
| **qa** | 品質保証・テスト |
| **reviewer** | 多次元コードレビュー (security/performance/architecture/testing/a11y) |

### 任意 (`--roles` で指定)
| ロール | 役割 |
|---|---|
| **release** | Git 操作・マージ・デプロイ調整 |
| **debugger** | 仮説駆動デバッグ (1仮説を担当して証拠収集) |
| **researcher** | コードベース・先行事例調査 (実装はしない) |
| **architect** | 設計選択肢評価・ADR 作成 |
| **designer** | UI/UX 仕様作成 |
| **data** | データ分析・スキーマ設計・マイグレーション |
| **security** | セキュリティ深掘りレビュー |
| **docs** | 技術文書・README・ADR・runbook |

加えて、プロジェクトレベル司令塔として **chief-pdm** が1つ自動生成される。

### プロジェクト固有ロール

`<project>/.kiro/agent-templates/team-<role>.json` を置くと汎用テンプレより優先される。
プロジェクト固有のロール (例: educator / marketer / seo-specialist) はここに置く。

## ディレクトリ構造

### フレームワーク (`~/kiro-team/`)
```
~/kiro-team/
├── README.md
├── agents/templates/         # 13ロール + chief-pdm の汎用テンプレ
├── scripts/
│   ├── install.sh            # プロジェクトに導入 (薄いシム生成)
│   ├── setup-teams.sh        # 案件起動 (汎用本体)
│   ├── stop-teams.sh         # 停止 (汎用本体)
│   ├── team-notifier.sh      # 案件単位 notifier (タスク配送・自律ping)
│   └── chief-notifier.sh     # プロジェクト全体 notifier
└── steering/                 # ブランチ戦略・施策管理ルール (任意参照)
```

### プロジェクト側 (`<project>/`)
```
<project>/
├── kiro-team/
│   ├── scripts/
│   │   ├── setup.sh          # ~/kiro-team/scripts/setup-teams.sh への shim
│   │   └── stop.sh           # ~/kiro-team/scripts/stop-teams.sh への shim
│   ├── plans/                # 施策計画
│   ├── teams/<initiative>/   # 案件ごとの tasks/, results/, plans/ (自動作成)
│   └── teams.conf            # --all 用の案件定義 (任意)
└── .kiro/
    ├── agents/               # 案件PdM/specialists 定義 (自動生成)
    │   ├── chief-pdm.json    # 初回 setup 時に生成
    │   └── <initiative>-<role>.json
    └── agent-templates/      # プロジェクト固有テンプレ override (任意)
```

## 導入

```bash
# 1. ライブラリを取得 (一度だけ)
git clone <repo> ~/kiro-team

# 2. プロジェクトに導入 (シム + ディレクトリ + teams.conf.example を生成)
~/kiro-team/scripts/install.sh ~/Desktop/projects/myproject
```

ライブラリの場所は `KIRO_TEAM_HOME` 環境変数で上書き可能 (デフォルト `$HOME/kiro-team`)。

## 使い方

```bash
cd ~/Desktop/projects/myproject

# 案件1つ起動 (引数: <initiative> <branch>)
./kiro-team/scripts/setup.sh blog content-main

# ロール指定
./kiro-team/scripts/setup.sh api-rewrite api-rewrite-main \
  --roles pdm,backend,qa,reviewer,architect

# ping 無効化 (手動駆動運用)
./kiro-team/scripts/setup.sh quick-fix quick-fix-main --no-ping

# teams.conf に書いた全案件を一括起動
cp kiro-team/teams.conf.example kiro-team/teams.conf  # 編集
./kiro-team/scripts/setup.sh --all

# 停止
./kiro-team/scripts/stop.sh             # 全案件 + chief
./kiro-team/scripts/stop.sh blog        # 1案件のみ (chief は残す)

# セッションに接続
tmux attach -t kiro-myproject-chief     # chief PdM
tmux attach -t kiro-myproject-blog      # 案件 PdM
```

### `teams.conf` 形式

```
# <initiative>:<branch>[:<roles>]
blog:content-main:pdm,frontend,qa,reviewer
api-rewrite:api-rewrite-main:pdm,backend,qa,reviewer,architect
quick-fix:quick-fix-main
```

`<roles>` 省略時はコア5ロール (pdm,frontend,backend,qa,reviewer)。

## 案件のライフサイクル

```
1. ユーザー → chief-pdm: 案件を相談、KPI と方針を合意
2. ユーザー: ./kiro-team/scripts/setup.sh <init> <br> で worktree + tmux + 案件 PdM 起動
3. chief-pdm or ユーザー: tasks/<init>-pdm.md にブリーフを書く
4. 案件 PdM: 受信 → タスク分解 → tasks/<init>-<role>.md に specialists 用タスク投入
5. team-notifier: tasks/ を検知 → specialist の tmux ペインに配送
6. specialist: 実行 → results/<init>-<role>.md に結果書き込み
7. team-notifier: results/ を検知 → 案件 PdM に [SYSTEM] 通知
8. 案件 PdM: 結果統合 → results/<init>-pdm.md を更新
9. chief-pdm: results/ を見て案件横断調整 + ユーザー報告
10. クローズ: ./kiro-team/scripts/stop.sh <init>
```

## 通信プロトコル

### タスクファイル (`tasks/<initiative>-<role>.md`)
```
TASK_ID: <unique-id>
OWNER: <initiative>-<role>
DEPENDS_ON: <other-task-ids or none>
FILE_OWNERSHIP: <files this task can modify>
---
## Goal
<what to achieve>

## Acceptance Criteria
<concrete, verifiable conditions>
```

### 結果ファイル (`results/<initiative>-<role>.md`)
```
TASK_ID: <id>
STATUS: COMPLETE | BLOCKED | QUESTION | APPROVED | CHANGES_REQUESTED | ...
---
<content>
```

ロールごとに STATUS の取りうる値が異なる (reviewer は APPROVED/CHANGES_REQUESTED、qa は PASSED/FAILED など)。詳細は各テンプレを参照。

## 自律運用 (`--no-ping` で無効化可能)

`team-notifier.sh` が30分ごとに案件 PdM に自律チェックを促す。
chief-notifier は1時間ごとに chief-pdm に全案件チェックを促す (常時 ON)。

```
[案件 PdM ping] 自律チェック: 各スペシャリストの進捗を確認してください。
                アイドル中のスペシャリストに次のタスクを委譲、
                ブロッカーがあれば解消...

[chief PdM ping] 全案件定期チェック: 各案件 (kiro-team/teams/<initiative>/) の
                  plans/ と results/<initiative>-pdm.md を確認し...
```

長時間 (1時間) notifier ログが更新されない案件は chief への ping に "stalled" として表示される。

## 設定

### `setup-teams.sh` のオプション
| フラグ | 説明 |
|---|---|
| `--roles <list>` | 使用ロール (default: pdm,frontend,backend,qa,reviewer) |
| `--no-ping` | 案件 PdM の定期 ping を無効化 |
| `--all` | `<project>/kiro-team/teams.conf` を読んで全案件起動 |

### `team-notifier.sh` の定数
- `POLL_INTERVAL=5` — タスク/結果監視間隔 (秒)
- `PROMPT_TIMEOUT=60` — エージェントのプロンプト待機タイムアウト
- 第3引数で ping 間隔 (秒) を指定。`0` で無効

### `chief-notifier.sh` の定数
- `PING_INTERVAL=3600` — chief への自律チェック間隔 (1時間)
- `STALL_THRESHOLD=3600` — notifier が無音と判断する閾値

## トラブルシューティング

### setup を再実行したらタスクが届かなくなった
旧セッションの specialist `.pane_*` ファイルが残っているとエージェントペイン未作成のまま skip される。
`./kiro-team/scripts/stop.sh <initiative>` を打ってから setup し直す。

### notifier が複数走っている
`pgrep -af team-notifier` で確認。stop で全 kill されるが、強制終了で残った場合は手動で `pkill -f team-notifier`。

### エージェント定義 not found エラー
`tasks/<initiative>-<role>.md` のファイル名と `.kiro/agents/` 内のエージェント定義名が一致しているか確認。
存在しないロールに対応するタスクを書いた場合は、`setup.sh` を `--roles ...` に当該ロールを含めて再実行する必要がある。
