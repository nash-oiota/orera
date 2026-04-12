# Vision: kiro-team

## Executive Summary

kiro-team is a personal CLI tool that builds a multi-agent development team using tmux and kiro-cli. The user gives instructions to a PdM agent, and the PdM autonomously delegates tasks to specialized agents (frontend, backend, infra, etc.) running in separate tmux sessions. The user only interacts with the PdM — the rest happens automatically.

## Problem Statement

When using kiro-cli for software development, the user must manually switch contexts and manage multiple concerns simultaneously. kiro-team solves this by simulating a real development team: a PdM receives requirements and coordinates specialists, each running as a persistent kiro-cli session in its own tmux window.

## Target Users

| User | Needs |
|---|---|
| Individual developer (primary) | Give a requirement to PdM and get results without managing each agent manually |
| Team members (secondary) | Share the tool configuration and run the same team setup |

## Features Implemented (MVP+)

| Feature | Description |
|---|---|
| Team startup | `start.sh` で PdM + watcher + notifier 起動 |
| Team shutdown | `stop.sh` で停止（--archive / --clean オプション付き） |
| PdM agent | タスク分解・委任・自律判断・マネジメント・状態復元 |
| Specialist agents | frontend / backend / infra / qa（動的起動） |
| Reviewer agent | frontend + backend の結合レビュー |
| Configurable team | `.kiro/agents/*.json` でチーム構成 |
| Task delivery | notifier.sh が tasks/ を監視して specialist に配送 |
| Result collection | watcher.sh が results/ を監視して PdM に通知 |
| Multi-project support | SESSION_NAME をプロジェクト名に自動設定 |
| Global install | `install.sh` で `~/kiro-team/` にインストール |
| Pane layout | pdm と specialist をペイン分割で並べて表示 |

## Features In Scope (MVP)

| Feature | Description |
|---|---|
| Team startup | Single command launches all tmux sessions with kiro-cli running in each |
| Team shutdown | Single command kills all sessions |
| PdM agent | Receives user instructions, decomposes tasks, delegates to agents via tmux send-keys |
| Specialist agents | Each agent runs kiro-cli persistently in its own tmux session |
| Configurable team | Team roles defined by `.kiro/agents/*.json` files — add a JSON file to add a team member |
| Task delegation | PdM sends instructions to specialist sessions using tmux send-keys |
| Result collection | Specialists write results to `results/<agent>.md`; PdM reads and reports back |

## Features Explicitly Out of Scope (MVP)

| Feature | Reason | Future Phase |
|---|---|---|
| Jira 連携（MCP経由） | チケット自動作成・更新 | Phase 2 |
| Slack 通知 | 完了通知・バグ報告 | Phase 2 |
| コンテキスト肥大化対策 | 長時間稼働で応答が遅くなる問題 | Phase 2 |
| エラーリトライロジック | BLOCKED 時の自動対処 | Phase 2 |
| 動的エージェント追加/削除 | 実行中にチームを変更 | Phase 2 |
| GitHub PR 自動作成 | `gh pr create` で連携 | Phase 2 |
| linter/formatter 自動実行 | 品質担保 | Phase 2 |
| add-agent.sh テンプレート | エージェント追加を簡単に | Phase 2 |
| Web UI / dashboard | Overkill for personal tool | Phase 2 |
| Dynamic agent add/remove at runtime | Static team is sufficient for MVP | Phase 2 |
| Slack / email notifications | Not needed for personal use | Phase 2 |
| Cloud deployment | Local only | Phase 3 |
| Multiple simultaneous projects | Single team per terminal session is enough | Phase 2 |
| Error retry logic | Manual intervention acceptable for MVP | Phase 2 |

## Open Questions

- Does `kiro-cli chat` support non-interactive pipe input (`echo "task" | kiro-cli chat`)? If yes, simpler task delivery is possible. If no, tmux send-keys is the only option.
- How does the PdM know when a specialist has finished? (polling `results/` vs specialist sending a completion signal)
- How to handle kiro-cli context bloat in long-running sessions?
