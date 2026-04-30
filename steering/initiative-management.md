# 案件管理ルール

このドキュメントは kiro-team を使ったプロジェクトの **案件 (initiative) 運営ルール** を定義する。
chief-pdm および各案件 PdM はこのルールを遵守すること。

## 1. 組織構成

```
chief-pdm (プロジェクト司令塔)
  ├── <initiative-A>-pdm
  │     ├── <initiative-A>-frontend
  │     ├── <initiative-A>-backend
  │     ├── <initiative-A>-qa
  │     └── <initiative-A>-reviewer
  ├── <initiative-B>-pdm
  │     └── ...
  └── ...
```

- **chief-pdm**: ユーザー対話、案件横断の優先順位、調停、エスカレーション
- **<initiative>-pdm**: 案件1つを率いる司令塔。タスク分解・委譲・統合
- **specialists**: pdm から委譲されたタスクを実行（実装・テスト・レビュー等）

## 2. 案件のライフサイクル

```
1. chief-pdm ↔ ユーザー: 案件のゴールと KPI を合意
2. ユーザー: setup-teams.sh で worktree + tmux セッション + agent 定義を起動
3. chief-pdm or ユーザー: tasks/<initiative>-pdm.md にブリーフを書く
4. <initiative>-pdm: 受信 → タスク分解 → specialists にタスク委譲
5. specialists: 実行 → results/<initiative>-<role>.md に結果書き込み
6. <initiative>-pdm: 結果統合 → results/<initiative>-pdm.md を更新
7. chief-pdm: 案件横断で進捗確認、ユーザーに報告
8. クローズ: KPI 達成 or 中止判断 → stop-teams.sh で停止
```

## 3. Notifier Contract（必須遵守ルール）

`team-notifier.sh` がタスク配送と新ウィンドウ起動を行う。以下のルールを **絶対に** 守ること。違反すると notifier が agent を解決できず、タスクが届かない。

### 3.1 タスクファイル命名
タスクファイルのパスとファイル名は厳密にこの形式:
```
kiro-team/teams/<initiative>/tasks/<initiative>-<role>.md
```
- `<initiative>` は worktree と一致（例: `blog`, `api-rewrite`）
- `<role>` は `.kiro/agents/` に存在するロール名（例: `frontend`, `backend`, `qa`, `reviewer`, `pdm`, ...）
- ファイル名 = エージェント名 = `<initiative>-<role>`
- 使える文字: `[a-zA-Z0-9_-]` のみ

✅ OK: `kiro-team/teams/blog/tasks/blog-frontend.md`
❌ NG: `kiro-team/teams/blog/tasks/frontend.md`（initiative prefix なし）
❌ NG: `kiro-team/teams/blog/tasks/blog-fe.md`（agent 定義に `blog-fe.json` が無い）
❌ NG: `kiro-team/teams/blog/tasks/blog-frontend-pageA.md`（複数タスクは内容で分けず、ファイルを上書きする）

### 3.2 結果ファイル命名
結果ファイルもタスクと同じ命名規則:
```
kiro-team/teams/<initiative>/results/<initiative>-<role>.md
```

### 3.3 ロールは agent 定義済みのものに限る
`<initiative>-pdm` がタスクを書き込む前に、`.kiro/agents/<initiative>-<role>.json` の存在を確認すること。
存在しないロールにタスクを書くと notifier はエラーログを出して PdM 自身に通知を返す。
新ロールが必要な場合: `setup-teams.sh --roles <初期ロール>,<追加ロール>` で再実行（既存は上書きされない）。

### 3.4 同一案件内の同じロールへの新規タスクは「ファイル上書き」
- task ファイルは agent ごとに1つ。新タスクは古いタスクを上書きする
- 並列に複数タスクを投げたい場合は `DEPENDS_ON` で逐次化するか、複数ロールを使う
- notifier は `mtime` で新規判定する: `<role>.sent` より `<role>.md` が新しければ再送

### 3.5 タスクファイル内のメタデータ
PdM は specialists 用タスクに以下のヘッダを必ず含める:
```
TASK_ID: <unique-id>
OWNER: <initiative>-<role>
DEPENDS_ON: <other-task-ids or none>
FILE_OWNERSHIP: <files this task can modify>
---
## Goal
...
## Acceptance Criteria
...
```

### 3.6 結果ファイルの STATUS
specialists は結果ファイルの先頭に必ず STATUS を書く:
```
TASK_ID: <id>
STATUS: <ロール固有の値>
---
<content>
```
ロール別の STATUS 値:
- pdm: `IN_PROGRESS | BLOCKED | COMPLETE`
- frontend / backend: `QUESTION | BLOCKED | COMPLETE`
- qa: `PASSED | FAILED | BLOCKED`
- reviewer: `APPROVED | CHANGES_REQUESTED`
- release: `COMPLETE | BLOCKED`
- debugger: `CONFIRMED | FALSIFIED | INCONCLUSIVE`

詳細は各ロールの `agents/templates/team-<role>.json` を参照。

## 4. 計画ファイル

- 計画は `kiro-team/teams/<initiative>/plans/<施策名>.md` に置く
- フォーマットはプロジェクト側で `kiro-team/plans/TEMPLATE.md` を用意して参照させる
- 必須項目: 作成日、完了予定日、ステータス、ゴール、KPI、タスク一覧

## 5. 開発フロー（標準パターン）

```
<initiative>-pdm
  ↓ タスク委譲
specialists（frontend / backend など）
  ↓ 実装完了 → results に書き込み
<initiative>-reviewer
  ↓ APPROVED
<initiative>-qa
  ↓ PASSED
完了
```

reviewer が CHANGES_REQUESTED を返した場合、pdm は specialist に修正タスクを再投入する。

## 6. ブランチ戦略

詳細は `branch-strategy.md` を参照。要約:
- 案件1つにつき `feature/<branch>` ブランチ1つ + worktree 1つ
- develop へのマージは release ロール（または pdm の判断）が実行
- main への直接 push 禁止

## 7. 自律運用（任意）

`team-notifier.sh` は 30分ごとに `<initiative>-pdm` に自律チェックを促す（`--no-ping` で無効化可能）。
PdM は ping を受けたら以下を実行:
1. specialists の results を確認
2. アイドル中の specialist に次のタスクを委譲
3. ブロッカーがあれば解消（または chief にエスカレーション）
4. 全タスク完了なら次のイテレーションを計画
5. 本当に外部入力待ちの場合のみ `待機中: <理由>` と報告

`chief-notifier.sh` は 1時間ごとに chief-pdm に全案件チェックを促す（常時有効）。

## 8. コミットメッセージ

[Conventional Commits](https://www.conventionalcommits.org/) 形式:
```
<type>(<scope>): <subject>

<body>

Closes #<issue-number>
```

type 例: `feat`, `fix`, `refactor`, `docs`, `test`, `chore`
