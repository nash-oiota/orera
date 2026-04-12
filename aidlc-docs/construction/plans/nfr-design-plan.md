# NFR Design Plan — Unit 1: scripts & Unit 2: agent-configs

## チェックリスト

- [ ] NFR 設計質問への回答収集
- [ ] Unit 1 の nfr-design-patterns.md を生成
- [ ] Unit 1 の logical-components.md を生成
- [ ] Unit 2 の nfr-design-patterns.md を生成
- [ ] Unit 2 の logical-components.md を生成

---

## 質問

### Question 1
notifier.sh が send-keys に失敗した場合（例: セッションが消えていた）、リトライしますか？

A) リトライなし（エラーを stderr に出力してそのエージェントをスキップ）
B) 一定回数リトライしてから諦める（例: 3回）
C) Other (please describe after [Answer]: tag below)

[Answer]: 

---

### Question 2
エージェント名の入力値検証はどの程度行いますか？

A) 英数字・ハイフン・アンダースコアのみ許可（正規表現チェック）
B) 検証なし（JSON の name フィールドをそのまま使う）
C) Other (please describe after [Answer]: tag below)

[Answer]: 
