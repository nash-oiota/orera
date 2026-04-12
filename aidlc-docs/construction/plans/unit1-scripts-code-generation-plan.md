# Code Generation Plan — Unit 1: scripts

## ユニット概要
- **対象**: Shell スクリプト群
- **プロジェクトルート**: `/Users/naoish/Desktop/orera`
- **出力先**: `scripts/` ディレクトリ + `README.md`

## 要件カバレッジ
- FR-01: start.sh
- FR-02: notifier.sh の ensure_session()
- FR-03b: notifier.sh
- FR-05: watcher.sh
- FR-07: stop.sh
- FR-08: status.sh

## 生成ステップ

- [x] Step 1: `scripts/` ディレクトリ作成
- [x] Step 2: `scripts/config.sh` 生成（共通設定）
- [x] Step 3: `scripts/start.sh` 生成（PdM + watcher + notifier 起動、エージェント名検証）
- [x] Step 4: `scripts/stop.sh` 生成（全セッション停止）
- [x] Step 5: `scripts/status.sh` 生成（セッション生死 + results/ 更新時刻）
- [x] Step 6: `scripts/watcher.sh` 生成（results/ 監視・PdM 通知）
- [x] Step 7: `scripts/notifier.sh` 生成（tasks/ 監視・specialist 配送）
- [x] Step 8: `README.md` 生成（使い方・デバッグガイド）
- [x] Step 9: `aidlc-docs/construction/unit1-scripts/code/code-summary.md` 生成
