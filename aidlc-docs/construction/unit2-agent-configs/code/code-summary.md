# Code Summary — Unit 2: agent-configs

## 生成ファイル

| ファイル | 説明 |
|---|---|
| .kiro/agents/pdm.json | PdM + TL。委任・自律判断・マネジメント指針含む詳細プロンプト |
| .kiro/agents/frontend.json | フロントエンド専門（UI/UX・アクセシビリティ・レスポンシブ） |
| .kiro/agents/backend.json | バックエンド専門（API・ビジネスロジック・DB） |
| .kiro/agents/infra.json | インフラ専門（デプロイ・環境構成・CI/CD） |
| .kiro/agents/qa.json | QA 専門（テスト設計・品質管理・バグ分析） |

## プロンプト共通構造

全 specialist に以下を含む：
1. 役割定義と専門領域
2. SYSTEM メッセージ受信時の動作（tasks/<name>.md を読んで実行）
3. results/ 書き込みルール（STATUS フォーマット厳守）
4. スコープ制限（専門外は QUESTION）
5. 専門領域ガイドライン
6. セキュリティルール（シークレット禁止）
