# Logical Components — Unit 1: scripts

## コンポーネント構成

```
config.sh          # 設定レイヤー（全スクリプトが依存）
    |
    +-- start.sh   # ライフサイクル管理（起動）
    +-- stop.sh    # ライフサイクル管理（停止）
    +-- status.sh  # 観測レイヤー
    +-- watcher.sh # イベント検知レイヤー（results/ → PdM）
    +-- notifier.sh# イベント配送レイヤー（tasks/ → specialist）
```

## 各コンポーネントの NFR 責務

| コンポーネント | 信頼性 | セキュリティ |
|---|---|---|
| config.sh | 設定値の一元管理 | シークレット禁止 |
| start.sh | 前提条件チェック + エージェント名検証 | 入力値検証（正規表現） |
| stop.sh | セッション存在確認後に kill | — |
| status.sh | 存在しないセッションを graceful に処理 | — |
| watcher.sh | ポーリングループ + 非致命的エラーをスキップ | — |
| notifier.sh | ポーリングループ + タイムアウト付き待機 + 非致命的エラーをスキップ | — |
