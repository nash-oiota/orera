# kiro-team

tmux + kiro-cli を使ったマルチエージェント開発チームツール。PdM に指示するだけで、specialist が自律的にタスクを分担して開発を進める。

## 必要なもの

- tmux
- kiro-cli

## インストール

プロジェクトに kiro-team をセットアップする：

```bash
bash ~/kiro-team/scripts/install.sh /path/to/your-project
```

インストール後の構成：

```
your-project/
├── kiro-team/
│   ├── scripts/   # start.sh, stop.sh 等
│   ├── tasks/     # PdM が書くタスクファイル（自動生成）
│   ├── results/   # specialist が書く結果ファイル（自動生成）
│   └── logs/      # セッションログ（自動生成）
└── .kiro/
    └── agents/    # kiro-team-*.json（kiro-cli が読む）
```

## 使い方

```bash
cd your-project

# チーム起動
./kiro-team/scripts/start.sh

# チーム停止
./kiro-team/scripts/stop.sh            # 通常停止
./kiro-team/scripts/stop.sh --archive  # アーカイブして停止
./kiro-team/scripts/stop.sh --clean    # 完全リセット

# 状態確認
./kiro-team/scripts/status.sh
```

## チーム構成

| エージェント | 役割 |
|---|---|
| kiro-team-pdm | PdM + TL。ユーザーと会話し、specialist に委任 |
| kiro-team-frontend | UI/UX 実装 |
| kiro-team-backend | API・ビジネスロジック実装 |
| kiro-team-infra | デプロイ・環境構成 |
| kiro-team-qa | テスト・品質管理 |
| kiro-team-reviewer | frontend + backend の結合レビュー |

## エージェントの追加

### 1. エージェント定義ファイルを作成

`~/kiro-team/.kiro/agents/kiro-team-<name>.json` を作成する。
ファイル名と `name` フィールドは必ず一致させること。

```json
{
  "name": "kiro-team-designer",
  "prompt": "You are a UI Designer specialist in kiro-team.\n\n## IMPORTANT: Execution Constraints\n- NEVER start long-running processes\n\n## Your Role\n...\n\n## Receiving Tasks\nWhen you receive a [SYSTEM] message, immediately read kiro-team/tasks/kiro-team-designer.md and execute the task.\n\n## Reporting Results\nWrite to kiro-team/results/kiro-team-designer.md:\n```\nTASK_ID: <id>\nSTATUS: QUESTION | BLOCKED | COMPLETE\n---\n<content>\n```",
  "tools": ["execute_bash", "fs_write", "fs_read"],
  "allowedTools": ["execute_bash", "fs_write", "fs_read"],
  "resources": [
    "file://~/kiro-team/steering/branch-strategy.md"
  ]
}
```

### 2. PdM のエージェントリストを更新

`~/kiro-team/.kiro/agents/kiro-team-pdm.json` の `## Team Members` セクションに追加：

```
- kiro-team-designer: UI design, wireframes, design system
```

また `## Task Delegation` の Examples にも追加：

```
- kiro-team/tasks/kiro-team-designer.md
```

### 3. プロジェクトに再インストール

```bash
bash ~/kiro-team/scripts/install.sh /path/to/your-project
```

## 設定変更

`kiro-team/scripts/config.sh` で変更できる：

| 変数 | デフォルト | 説明 |
|---|---|---|
| POLL_INTERVAL | 5 | ポーリング間隔（秒） |
| STARTUP_WAIT | 5 | kiro-cli 起動待ち（秒） |
| PROMPT_TIMEOUT | 60 | プロンプト待ちタイムアウト（秒） |

## デバッグ

```bash
Ctrl+b w  # ウィンドウ一覧から specialist を選択して確認
```

ログは `kiro-team/logs/session-*.log` に記録される。

## 再起動時の動作

再起動時、未送信タスクは自動再送される（意図した動作）。
完全リセットしたい場合は `--clean` オプションを使う。
