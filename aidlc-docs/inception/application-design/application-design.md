# Application Design — kiro-team

## 概要

kiro-team は tmux + kiro-cli を使ったマルチエージェント開発チームツール。ユーザーは PdM とチャットするだけで、PdM が specialist に自律的にタスクを委任・管理する。

---

## コンポーネント構成

### Shell Scripts

| コンポーネント | 責務 |
|---|---|
| config.sh | 共通設定の一元管理（セッション名・パス・ポーリング間隔） |
| start.sh | PdM + watcher + notifier 起動、ディレクトリ初期化 |
| stop.sh | 全セッション停止 |
| status.sh | セッション生死 + results/ 更新時刻の表示 |
| watcher.sh | results/ 定期ポーリング → capture-pane で PdM 待機確認 → 未通知かつ待機中のみ通知（.notified マーク管理）（常駐） |
| notifier.sh | tasks/ 定期ポーリング → capture-pane で specialist 待機確認 → 未送信かつ待機中のみ配送（.sent マーク管理）（常駐） |

### Agent Configurations

| エージェント | 役割 |
|---|---|
| pdm | PdM + TL。タスク分解・委任・自律判断・マネジメント |
| frontend | フロントエンド専門（UI/UX、アクセシビリティ、レスポンシブ） |
| backend | バックエンド専門（API、ビジネスロジック、DB） |
| infra | インフラ専門（デプロイ、環境構成、CI/CD） |
| qa | QA 専門（テスト設計、品質管理、バグ分析） |
| reviewer | 結合レビュー専門（frontend + backend の統合観点でレビュー） |

### レビューフロー

```
frontend COMPLETE + backend COMPLETE
    → PdM が reviewer に結合レビューを依頼
    → APPROVED → qa にテスト依頼 → ユーザーに報告
    → CHANGES_REQUESTED → 該当 specialist に修正依頼 → 再レビュー
```

---

## 通信プロトコル

### タスク配送（PdM → specialist）

```
tasks/<agent-name>.md:

TASK_ID: <連番>
PRIORITY: high | medium | low
---
<タスク内容>
```

### 結果報告（specialist → PdM）

```
results/<agent-name>.md:

TASK_ID: <対応タスクID>
STATUS: QUESTION | BLOCKED | COMPLETE
---
<内容>
```

---

## エージェントプロンプト構成

### PdM プロンプト
1. 役割定義（PdM + TL）
2. チームメンバーと専門領域
3. タスク委任フロー（tasks/ への書き込み方法）
4. 自律判断ガイドライン（何をユーザーに確認し、何を自律実行するか）
5. SYSTEM メッセージ処理（results/ 確認 → STATUS 判断 → 次アクション）
6. TL としての進行管理・マネジメント指針

### specialist プロンプト（共通構造）
1. 役割定義と専門領域
2. SYSTEM メッセージ受信時の動作（tasks/<自分の名前>.md を読んで実行）
3. results/ 書き込みルール（STATUS フォーマット厳守）
4. スコープ制限（専門外は QUESTION で PdM に確認）
5. 専門領域ガイドライン（各 specialist 固有）

---

## 命名規約

エージェント識別子 = JSON `name` フィールド = ファイル名 = tmux ウィンドウ名 = tasks/<name>.md = results/<name>.md

start.sh 起動時に `name` フィールドとファイル名の一致を検証する。

---

## データフロー

```
ユーザー <-> PdM
              |
         tasks/<name>.md
              |
         notifier.sh（capture-pane でプロンプト確認後 send-keys）
              |
         specialist
              |
         results/<name>.md
              |
         watcher.sh（capture-pane で PdM プロンプト確認、未通知かつ待機中のみ send-keys）
              |
             PdM（自律判断 or ユーザーへ確認）
```
