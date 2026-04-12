# Application Design Plan — kiro-team

## 設計対象コンポーネント

1. **Shell Scripts**: start.sh / stop.sh / status.sh / watcher.sh / notifier.sh / config.sh
2. **Agent Configurations**: pdm.json / frontend.json / backend.json / infra.json / qa.json
3. **Communication Protocol**: tasks/ と results/ のファイルフォーマット

---

## 設計チェックリスト

- [x] 共通設定の管理方法を決定する → config.sh に集約
- [x] tasks/ ファイルフォーマットを定義する → 構造化フォーマット
- [x] notifier.sh のプロンプト待ち検知方法を決定する → tmux capture-pane
- [x] watcher.sh のポーリング間隔を決定する → config.sh で設定可能（デフォルト 5 秒）
- [x] PdM プロンプトの構成を定義する → 詳細 + マネジメント指針
- [x] specialist プロンプトの構成を定義する → 詳細 + 専門領域ガイドライン
- [ ] components.md を生成する
- [ ] component-methods.md を生成する
- [ ] services.md を生成する
- [ ] component-dependency.md を生成する
- [ ] application-design.md（統合ドキュメント）を生成する

---

## 設計回答サマリー

| 質問 | 回答 |
|---|---|
| 共通設定管理 | scripts/config.sh に集約、各スクリプトが source |
| tasks/ フォーマット | 構造化（TASK_ID, PRIORITY, DESCRIPTION） |
| プロンプト待ち検知 | tmux capture-pane で最終行確認 |
| ポーリング間隔 | config.sh で設定可能（デフォルト 5 秒） |
| PdM プロンプト | 役割 + 委任ルール + specialist 専門領域 + 命令フォーマット + 自律判断 + TL マネジメント |
| specialist プロンプト | 役割 + results/ 書き込みルール + 専門領域ガイドライン + tasks/ 確認ルール + スコープ制限 |
