# Logical Components — Unit 2: agent-configs

## エージェント階層

```
pdm.json           # オーケストレーター（判断・委任・マネジメント）
    |
    +-- frontend.json  # 実装レイヤー（UI/UX）
    +-- backend.json   # 実装レイヤー（API/ロジック）
    +-- infra.json     # 実装レイヤー（デプロイ/環境）
    +-- qa.json        # 品質レイヤー（テスト/検証）
```

## 各エージェントの NFR 責務

| エージェント | 信頼性 | セキュリティ |
|---|---|---|
| pdm | 自律判断の境界を明確化、不明時はユーザーにエスカレーション | シークレット禁止、tasks/ 書き込みのみ |
| frontend | 専門外は QUESTION、完了時は必ず STATUS 記載 | allowedTools 最小権限 |
| backend | 同上 | 同上 |
| infra | 同上 | 同上 |
| qa | 同上 | 同上 |
