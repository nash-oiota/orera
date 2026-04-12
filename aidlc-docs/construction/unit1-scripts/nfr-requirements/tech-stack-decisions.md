# Tech Stack Decisions — Unit 1: scripts

## 言語・ランタイム

| 項目 | 決定 | 理由 |
|---|---|---|
| 実装言語 | Bash | tech-env.md の方針。依存最小化 |
| 最低バージョン | Bash 3.2+ | macOS デフォルト互換 |
| 対応 OS | macOS / Linux | tech-env.md の方針 |

## 外部依存

| ツール | バージョン | 用途 |
|---|---|---|
| tmux | any recent | セッション管理・send-keys・capture-pane |
| kiro-cli | latest | AI エージェントランタイム |

## 禁止事項

- Python・Ruby 等のスクリプト言語（依存追加のため）
- fswatch・inotifywait（外部ツール依存のため）
- Redis 等のメッセージキュー（オーバースペックのため）
