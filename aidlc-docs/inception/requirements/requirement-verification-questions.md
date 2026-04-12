# Requirements Clarification Questions — kiro-team

## Question 1
デフォルトのスペシャリストエージェント構成はどれにしますか？

A) frontend + backend の2名
B) frontend + backend + infra の3名
C) frontend + backend + infra + qa の4名
D) カスタム（後述）
X) Other (please describe after [Answer]: tag below)

[Answer]: X — frontend + backend + infra + qa の4名。PdM にマネジメント能力（TL的役割）を含める。

---

## Question 2
PdM が specialist の完了を検知する方法はどれにしますか？

A) ポーリング（一定間隔で results/ を監視）
B) ファイル変更検知（`fswatch` や `inotifywait` を使用）
C) specialist が完了後に PdM セッションへ tmux send-keys で通知
D) Other (please describe after [Answer]: tag below)

[Answer]: X — watcher.sh が常時監視（polling）し、完了を検知したら tmux send-keys で PdM に通知。

---

## Question 3
`kiro-cli chat --agent <name>` の形式でエージェントを指定できることは確認済みですか？

A) はい、動作確認済み
B) 未確認だが、そのように動作すると想定している
C) 別のフラグ・コマンド形式を使う（後述）
D) Other (please describe after [Answer]: tag below)

[Answer]: B

---

## Question 4
PdM エージェントのシステムプロンプトの詳細度はどの程度にしますか？

A) 最小限（役割と委任ルールのみ）
B) 標準（役割・委任ルール・タスク分解ガイドライン）
C) 詳細（上記 + 各スペシャリストの専門領域の説明）
D) Other (please describe after [Answer]: tag below)

[Answer]: C — 詳細。各スペシャリストの専門領域、命令フォーマット、マネジメント能力、自律判断ガイドラインを含む。

---

## Question 5
スペシャリストエージェントの system prompt はどのように管理しますか？

A) 各 .kiro/agents/*.json に直接記述
B) 別ファイル（例: .kiro/agents/prompts/*.md）に分離して JSON から参照
C) Other (please describe after [Answer]: tag below)

[Answer]: A

---

## Question 6
`start.sh` 実行時の設計はどうしますか？

A) エラーを出して終了（ユーザーに手動で stop.sh を実行させる）
B) 既存セッションを自動的に kill して再起動
C) 既存セッションにアタッチする
D) Other (please describe after [Answer]: tag below)

[Answer]: X — start.sh は PdM と watcher.sh のみ起動。specialist は PdM が必要に応じて動的に起動・管理する。起動待ち sleep を含む。

---

## Question 7
`status.sh` で表示する情報はどれにしますか？

A) 各エージェントの tmux セッション生死のみ
B) セッション生死 + 最新の results/*.md の更新時刻
C) Other (please describe after [Answer]: tag below)

[Answer]: B — ユーザーと PdM（execute_bash 経由）の両方が利用する。

---

## Question: Security Extensions
Should security extension rules be enforced for this project?

A) Yes — enforce all SECURITY rules as blocking constraints (recommended for production-grade applications)
B) No — skip all SECURITY rules (suitable for PoCs, prototypes, and experimental projects)
X) Other (please describe after [Answer]: tag below)

[Answer]: A

---

## Question: Property-Based Testing Extension
Should property-based testing (PBT) rules be enforced for this project?

A) Yes — enforce all PBT rules as blocking constraints
B) Partial — enforce PBT rules only for pure functions and serialization round-trips
C) No — skip all PBT rules (suitable for simple CRUD applications, UI-only projects, or thin integration layers with no significant business logic)
X) Other (please describe after [Answer]: tag below)

[Answer]: C
