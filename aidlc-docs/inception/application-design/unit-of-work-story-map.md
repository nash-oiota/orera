# Unit of Work Story Map — kiro-team

## 機能要件とユニットのマッピング

| 要件ID | 内容 | Unit |
|---|---|---|
| FR-01 | チーム起動（start.sh） | Unit 1: scripts |
| FR-02 | specialist の動的管理（ensure_session） | Unit 1: scripts |
| FR-03 | タスク委任（tasks/ への書き込み） | Unit 2: agent-configs（PdM プロンプト） |
| FR-03b | タスク配送（notifier.sh） | Unit 1: scripts |
| FR-04 | 結果報告（results/ への書き込み） | Unit 2: agent-configs（specialist プロンプト） |
| FR-05 | 完了通知（watcher.sh） | Unit 1: scripts |
| FR-05b | results フォーマット（STATUS） | Unit 1 + Unit 2 共通仕様 |
| FR-06 | 自律判断 | Unit 2: agent-configs（PdM プロンプト） |
| FR-07 | チーム停止（stop.sh） | Unit 1: scripts |
| FR-08 | ステータス確認（status.sh） | Unit 1: scripts |
| FR-09 | チーム構成（*.json） | Unit 2: agent-configs |
| FR-10 | PdM エージェント定義 | Unit 2: agent-configs |

## カバレッジ確認

- Unit 1: FR-01, FR-02, FR-03b, FR-05, FR-07, FR-08 ✅
- Unit 2: FR-03, FR-04, FR-06, FR-09, FR-10 ✅
- 共通仕様: FR-05b ✅
- 未割当: なし ✅
