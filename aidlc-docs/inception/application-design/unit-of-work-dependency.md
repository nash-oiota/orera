# Unit of Work Dependency — kiro-team

## 依存関係マトリクス

| Unit | 依存先 | 依存内容 | 並行開発可否 |
|---|---|---|---|
| Unit 1: scripts | なし | — | 即時開始可能 |
| Unit 2: agent-configs | Unit 1（部分的） | tasks/, results/ のパス仕様 | パス仕様確定後に並行開発可能 |

## 開発順序

```
[Unit 1: scripts] -----> 完成
       |
       | ファイルパス仕様確定（tasks/, results/）
       v
[Unit 2: agent-configs] --> 完成（Unit 1 と並行可）
       |
       v
[Build and Test]
```

## 並行開発の条件

Unit 2 は以下が確定すれば Unit 1 と並行して開発できる：
- `TASKS_DIR="tasks"` のパス
- `RESULTS_DIR="results"` のパス
- tasks/<name>.md と results/<name>.md のフォーマット仕様

これらは config.sh と services.md で既に確定済みのため、**即時並行開発可能**。
