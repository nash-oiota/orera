# Services — kiro-team

## Task Delivery Service（notifier.sh が担当）

**責務**: PdM が書いたタスクを適切なタイミングで specialist に届ける

**フロー**:
1. tasks/ を定期ポーリング
2. 未送信タスクファイルを検知
3. 対象 specialist セッションが存在しなければ起動（ensure_session）
4. プロンプト待ち状態になるまで待機（wait_for_prompt）
5. タスクを send-keys で送信
6. 送信済みマーク（tasks/<name>.sent）を作成

---

## Result Notification Service（watcher.sh が担当）

**責務**: specialist の完了・質問・ブロックを PdM に通知する

**フロー**:
1. results/ を定期ポーリング
2. 未通知の変更（タイムスタンプ更新 + .notified マークなし）を検知
3. PdM セッションの capture-pane でプロンプト待ちか確認
4. プロンプト待ちなら `[SYSTEM] <name> updated results. Check results/<name>.md` を send-keys
5. results/<name>.notified を作成
6. PdM が処理中の場合はスキップ、次のポーリングで再試行

---

## Agent Lifecycle Service（PdM が execute_bash 経由で担当）

**責務**: specialist セッションの動的管理

**フロー**:
- タスク委任時：tasks/<name>.md にタスクを書く（配送は Task Delivery Service に委譲）
- セッション確認：tmux list-windows で存在確認
- ステータス確認：status.sh を execute_bash で実行

---

## ファイルフォーマット仕様

### tasks/<agent-name>.md
```
TASK_ID: <連番>
PRIORITY: high | medium | low
---
<タスク内容（自然言語）>
```

### results/<agent-name>.md
```
TASK_ID: <対応するタスクID>
STATUS: QUESTION | BLOCKED | COMPLETE
---
<内容>
```
