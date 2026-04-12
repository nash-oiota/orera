# Unit of Work — kiro-team

## Unit 1: scripts

**説明**: チームの起動・停止・監視・タスク配送を担う Shell スクリプト群

**プロジェクトルート**: `/Users/naoish/Desktop/orera`

**成果物**:
```
scripts/
├── config.sh       # 共通設定
├── start.sh        # PdM + watcher + notifier 起動
├── stop.sh         # 全セッション停止
├── status.sh       # セッション状態確認
├── watcher.sh      # results/ 監視・PdM 通知
└── notifier.sh     # tasks/ 監視・specialist 配送
```

**依存**: なし（Unit 2 より先に、または並行して開発可能）

---

## Unit 2: agent-configs

**説明**: PdM・specialist の kiro-cli エージェント設定ファイル群

**成果物**:
```
.kiro/
└── agents/
    ├── pdm.json
    ├── frontend.json
    ├── backend.json
    ├── infra.json
    └── qa.json
```

**依存**: Unit 1 のファイルパス仕様（tasks/, results/ のパス）が確定していること

---

## コード配置ルール

- アプリケーションコード: `/Users/naoish/Desktop/orera/` 直下
- ドキュメント: `aidlc-docs/` のみ
- 実行時生成ディレクトリ: `tasks/`, `results/`（start.sh が初期化）
