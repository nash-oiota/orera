# Execution Plan — kiro-team

## Analysis Summary

- **Project Type**: Greenfield
- **Risk Level**: Low（ローカルツール、ロールバック容易）
- **User-facing changes**: No（CLI ツール、UI なし）
- **Structural changes**: Yes（新規コンポーネント群）
- **Data model changes**: No
- **API changes**: No
- **NFR impact**: Yes（Security Baseline 有効、watcher ポーリング設計）

## Workflow Visualization

```
[Start]
  |
  +-- INCEPTION PHASE
  |     [x] Workspace Detection     COMPLETED
  |     [ ] Reverse Engineering     SKIP (Greenfield)
  |     [x] Requirements Analysis   COMPLETED
  |     [ ] User Stories            SKIP (CLI内部ツール、UIなし)
  |     [x] Workflow Planning       IN PROGRESS
  |     [ ] Application Design      EXECUTE
  |     [ ] Units Generation        EXECUTE
  |
  +-- CONSTRUCTION PHASE (Unit 1: scripts)
  |     [ ] Functional Design       SKIP
  |     [ ] NFR Requirements        EXECUTE
  |     [ ] NFR Design              EXECUTE
  |     [ ] Infrastructure Design   SKIP
  |     [ ] Code Generation         EXECUTE
  |
  +-- CONSTRUCTION PHASE (Unit 2: agent configs)
  |     [ ] Functional Design       SKIP
  |     [ ] NFR Requirements        EXECUTE
  |     [ ] NFR Design              EXECUTE
  |     [ ] Infrastructure Design   SKIP
  |     [ ] Code Generation         EXECUTE
  |
  +-- Build and Test                EXECUTE
  |
[Complete]
```

## Phases to Execute

### INCEPTION PHASE
- [x] Workspace Detection — COMPLETED
- [ ] Reverse Engineering — SKIP（Greenfield のため）
- [x] Requirements Analysis — COMPLETED
- [ ] User Stories — SKIP（ユーザー向け UI なし、内部 CLI ツール）
- [x] Workflow Planning — IN PROGRESS
- [ ] Application Design — EXECUTE
  - 理由：PdM・specialist のシステムプロンプト設計、エージェント間通信プロトコル（STATUS フォーマット等）の詳細設計が必要
- [ ] Units Generation — EXECUTE
  - 理由：scripts と agent configs は独立して実装可能な2ユニットに分解できる

### CONSTRUCTION PHASE

#### Unit 1: Shell Scripts
（start.sh / stop.sh / status.sh / watcher.sh / notifier.sh）

- [ ] Functional Design — SKIP（要件で十分に定義済み）
- [ ] NFR Requirements — EXECUTE（Security Baseline 有効、ポーリング間隔・エラーハンドリング設計）
- [ ] NFR Design — EXECUTE（NFR Requirements に続いて実行）
- [ ] Infrastructure Design — SKIP（ローカルツール、クラウドインフラなし）
- [ ] Code Generation — EXECUTE

#### Unit 2: Agent Configurations
（.kiro/agents/*.json — PdM・specialist プロンプト）

- [ ] Functional Design — SKIP（Application Design で設計済み）
- [ ] NFR Requirements — EXECUTE（Security Baseline：プロンプトへのシークレット混入防止等）
- [ ] NFR Design — EXECUTE
- [ ] Infrastructure Design — SKIP
- [ ] Code Generation — EXECUTE

### Build and Test — EXECUTE

### OPERATIONS PHASE
- [ ] Operations — PLACEHOLDER

## 想定ユニット構成

| Unit | 内容 | 依存 |
|---|---|---|
| Unit 1: scripts | start.sh, stop.sh, status.sh, watcher.sh, notifier.sh | なし |
| Unit 2: agent-configs | pdm.json, frontend.json, backend.json, infra.json, qa.json | Unit 1（ファイルパス参照） |

## Success Criteria

- `./scripts/start.sh` で PdM + watcher が起動する
- PdM がタスクを `tasks/` に書くと notifier が specialist に届ける
- specialist が `results/` に書くと watcher が PdM に通知する
- `./scripts/stop.sh` で全セッションが停止する
- `./scripts/status.sh` でセッション状態が確認できる
