# Code Generation Plan — Unit 2: agent-configs

## ユニット概要
- **対象**: kiro-cli エージェント設定ファイル群
- **プロジェクトルート**: `/Users/naoish/Desktop/orera`
- **出力先**: `.kiro/agents/` ディレクトリ

## 要件カバレッジ
- FR-03: PdM プロンプト（tasks/ 書き込み）
- FR-04: specialist プロンプト（results/ 書き込み）
- FR-06: PdM 自律判断ガイドライン
- FR-09: チーム構成（5エージェント）
- FR-10: PdM エージェント定義

## 生成ステップ

- [x] Step 1: `.kiro/agents/` ディレクトリ作成
- [x] Step 2: `.kiro/agents/pdm.json` 生成（詳細プロンプト + マネジメント指針）
- [x] Step 3: `.kiro/agents/frontend.json` 生成
- [x] Step 4: `.kiro/agents/backend.json` 生成
- [x] Step 5: `.kiro/agents/infra.json` 生成
- [x] Step 6: `.kiro/agents/qa.json` 生成
- [x] Step 7: `aidlc-docs/construction/unit2-agent-configs/code/code-summary.md` 生成
