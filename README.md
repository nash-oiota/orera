# kiro-team

tmux + kiro-cli で動く「**案件 (initiative) ごとの自律エージェントチーム**」フレームワーク。
1案件 = 1 worktree = 1 tmux セッション = 1 チーム (PdM + specialists) で並列実行する。

## コンセプト

- **案件単位の独立**: 1案件1 worktree。同一リポで複数案件を干渉なく並走できる
- **横断リポジトリ対応**: 複数リポジトリを横断する案件も1セッションで管理できる
- **グローバル chief**: `kiro-chief` が全プロジェクト・全案件を横断監視する
- **一括起動/停止**: `projects.conf` に案件を定義して `--all` で一括操作
- **ファイルベース通信**: tasks/<role>.md → results/<role>.md でタスク配送と結果回収
- **自律運用 (任意)**: 30分間隔の ping で PdM を自発的に駆動 (`--no-ping` で無効化可能)
- **テンプレ駆動**: 汎用ロールテンプレを `{team}` プレースホルダーで案件名に展開

## 必要なもの

- tmux
- kiro-cli
- git (worktree 対応)

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

加えて、全プロジェクト横断の司令塔として **chief-pdm** が1つ自動生成される (`~/.kiro/agents/chief-pdm.json`)。

### プロジェクト固有ロール

`<project>/.kiro/agent-templates/team-<role>.json` を置くと汎用テンプレより優先される。
プロジェクト固有のロール (例: educator / marketer) はここに置く。

## ディレクトリ構造

### フレームワーク (`~/kiro-team/`)
```
~/kiro-team/
├── README.md
├── projects.conf             # 全プロジェクト・全案件の定義
├── projects.conf.example     # サンプル
├── agents/templates/         # 汎用ロールテンプレ
├── scripts/
│   ├── install.sh            # プロジェクトに導入 (薄いシム生成)
│   ├── setup-teams.sh        # 案件起動 (汎用本体)
│   ├── setup-multi.sh        # 横断リポジトリ案件起動
│   ├── stop-teams.sh         # 停止 (汎用本体)
│   ├── team-notifier.sh      # 案件単位 notifier (タスク配送・自律ping)
│   └── chief-notifier.sh     # グローバル notifier (全プロジェクト監視)
└── steering/                 # ブランチ戦略・施策管理ルール (任意参照)
```

### プロジェクト側 (`<project>/`)
```
<project>/
├── kiro-team/
│   ├── scripts/
│   │   ├── setup.sh          # ~/kiro-team/scripts/setup-teams.sh への shim
│   │   ├── setup-multi.sh    # ~/kiro-team/scripts/setup-multi.sh への shim
│   │   └── stop.sh           # ~/kiro-team/scripts/stop-teams.sh への shim
│   ├── plans/                # 施策計画
│   └── teams/<initiative>/   # 案件ごとの tasks/, results/, plans/ (自動作成)
└── .kiro/
    ├── agents/               # 案件 PdM/specialists 定義 (自動生成)
    │   └── <initiative>-<role>.json
    └── agent-templates/      # プロジェクト固有テンプレ override (任意)
```

### 横断リポジトリ案件 (`setup-multi.sh` 使用時)
```
~/projects/your-modernization/          # セッションの作業場
├── your-app-modernization/             # worktree (your-app の feature/modernization-main)
├── your-deploy-modernization/          # worktree (your-deploy の feature/modernization-main)
└── kiro-team/teams/modernization/       # tasks/, results/, plans/
```

## 導入

```bash
# 1. ライブラリを取得 (一度だけ)
git clone <repo> ~/kiro-team

# 2. projects.conf を作成
cp ~/kiro-team/projects.conf.example ~/kiro-team/projects.conf
# 編集して案件を定義

# 3. 各プロジェクトに導入 (シム + ディレクトリを生成)
~/kiro-team/scripts/install.sh ~/projects/myproject
```

ライブラリの場所は `KIRO_TEAM_HOME` 環境変数で上書き可能 (デフォルト `$HOME/kiro-team`)。

## 使い方

### 一括起動/停止 (推奨)

```bash
# projects.conf に定義した全案件を一括起動
~/kiro-team/scripts/setup-teams.sh --all
~/kiro-team/scripts/setup-teams.sh --all --no-ping   # 自律ping 無効

# 全停止
~/kiro-team/scripts/stop-teams.sh --all

# 全停止 + worktree 削除
~/kiro-team/scripts/stop-teams.sh --all --clean
```

### 個別起動

```bash
cd ~/projects/myproject

# 単一リポ案件
./kiro-team/scripts/setup.sh blog content-main
./kiro-team/scripts/setup.sh api-rewrite api-rewrite-main \
  --roles pdm,backend,qa,reviewer,architect --no-ping

# 横断リポジトリ案件
./kiro-team/scripts/setup-multi.sh modernization mod-main \
  --repos your-app,your-deploy --roles pdm,backend,qa,reviewer,architect

# 停止
./kiro-team/scripts/stop.sh             # 全案件停止 (worktree 残す)
./kiro-team/scripts/stop.sh blog        # 1案件のみ
./kiro-team/scripts/stop.sh blog --clean  # 1案件停止 + worktree 削除
./kiro-team/scripts/stop.sh chief       # グローバル chief のみ停止
```

### セッションに接続

```bash
tmux attach -t kiro-chief                    # グローバル chief PdM
tmux attach -t kiro-myproject-blog           # 案件 PdM
```

### `projects.conf` 形式

```
# project:initiative:branch:roles[:repos]
your-app:redis-to-valkey:redis_to_valkey:pdm,frontend,backend,qa,reviewer
your-modernization:modernization:mod-main:pdm,backend,qa,reviewer,architect:your-app,your-deploy
```

`repos` を指定すると横断リポジトリ案件として `setup-multi.sh` が呼ばれる。

## 案件のライフサイクル

```
1. ユーザー → chief-pdm: 案件を相談、KPI と方針を合意
2. projects.conf に案件を追加
3. ~/kiro-team/scripts/setup-teams.sh --all で起動
4. chief-pdm or ユーザー: tasks/<init>-pdm.md にブリーフを書く
5. 案件 PdM: 受信 → タスク分解 → tasks/<init>-<role>.md に specialists 用タスク投入
6. team-notifier: tasks/ を検知 → specialist の tmux ペインに配送
7. specialist: 実行 → results/<init>-<role>.md に結果書き込み
8. team-notifier: results/ を検知 → 案件 PdM に [SYSTEM] 通知
9. 案件 PdM: 結果統合 → results/<init>-pdm.md を更新
10. chief-pdm: 全プロジェクトの results/ を見て横断調整 + ユーザー報告
11. クローズ: stop.sh <init> --clean
```

## 通信プロトコル

### タスクファイル (`kiro-team/teams/<initiative>/tasks/<initiative>-<role>.md`)
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

### 結果ファイル (`kiro-team/teams/<initiative>/results/<initiative>-<role>.md`)
```
TASK_ID: <id>
STATUS: COMPLETE | BLOCKED | QUESTION | APPROVED | CHANGES_REQUESTED | PASSED | FAILED
---
<content>
```

## 設定

### `setup-teams.sh` / `setup-multi.sh` のオプション
| フラグ | 説明 |
|---|---|
| `--roles <list>` | 使用ロール (default: pdm,frontend,backend,qa,reviewer) |
| `--no-ping` | 案件 PdM の定期 ping を無効化 |
| `--all` | `~/kiro-team/projects.conf` を読んで全案件起動 |
| `--repos <list>` | 横断リポジトリ名 (setup-multi.sh / --all 時) |

### `stop-teams.sh` のオプション
| フラグ | 説明 |
|---|---|
| `--all` | `~/kiro-team/projects.conf` を読んで全案件停止 |
| `--clean` | セッション停止 + worktree 削除 |

### 環境変数
| 変数 | 説明 | デフォルト |
|---|---|---|
| `KIRO_TEAM_HOME` | ライブラリの場所 | `~/kiro-team` |
| `KIRO_TEAM_PROJECTS_DIR` | プロジェクトのルートディレクトリ | `~/projects` |

## トラブルシューティング

### setup を再実行したらタスクが届かなくなった
旧セッションの specialist `.pane_*` ファイルが残っているとエージェントペイン未作成のまま skip される。
`stop.sh <initiative>` を打ってから setup し直す。

### notifier が複数走っている
`pgrep -af team-notifier` で確認。stop で全 kill されるが、強制終了で残った場合は手動で `pkill -f team-notifier`。

### エージェント定義 not found エラー
`tasks/<initiative>-<role>.md` のファイル名と `.kiro/agents/` 内のエージェント定義名が一致しているか確認。
存在しないロールに対応するタスクを書いた場合は、`setup.sh` を `--roles ...` に当該ロールを含めて再実行する必要がある。

### setup-multi.sh で repos not found エラー
`--repos` に指定したリポジトリが `~/projects/` 配下に存在するか確認。
`KIRO_TEAM_PROJECTS_DIR` で別のディレクトリを指定している場合はそちらを確認。





