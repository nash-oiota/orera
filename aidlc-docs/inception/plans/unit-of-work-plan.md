# Unit of Work Plan — kiro-team

## 分解方針

Application Design で特定した2つのユニットに分解する。

| Unit | 内容 |
|---|---|
| Unit 1: scripts | config.sh / start.sh / stop.sh / status.sh / watcher.sh / notifier.sh |
| Unit 2: agent-configs | .kiro/agents/pdm.json / frontend.json / backend.json / infra.json / qa.json |

## 回答サマリー

| 質問 | 回答 |
|---|---|
| 開発順序 | 並行開発（ファイルパス仕様確定次第） |
| プロジェクトルート | /Users/naoish/Desktop/orera |

---

## 計画チェックリスト

- [ ] unit-of-work.md を生成する
- [ ] unit-of-work-dependency.md を生成する
- [ ] unit-of-work-story-map.md を生成する
