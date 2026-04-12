# Component Methods — kiro-team

## config.sh — 設定値

```bash
SESSION_NAME="kiro-team"          # tmux セッション名
AGENTS_DIR=".kiro/agents"         # エージェント JSON ディレクトリ
TASKS_DIR="tasks"                 # タスクファイルディレクトリ
RESULTS_DIR="results"             # 結果ファイルディレクトリ
POLL_INTERVAL=5                   # ポーリング間隔（秒）
PROMPT_PATTERN="> *$"            # kiro-cli プロンプト検知パターン（行末の > でマッチ、PdM・specialist 共通）
STARTUP_WAIT=10                   # セッション起動待ち（秒）
```

---

## start.sh

### init_directories()
- **目的**: tasks/ と results/ ディレクトリを作成する
- **入力**: なし
- **出力**: なし

### start_pdm()
- **目的**: PdM の tmux ウィンドウを作成し kiro-cli を起動する
- **入力**: なし
- **出力**: なし

### start_watcher()
- **目的**: watcher.sh を tmux ウィンドウで起動する
- **入力**: なし
- **出力**: なし

### start_notifier()
- **目的**: notifier.sh を tmux ウィンドウで起動する
- **入力**: なし
- **出力**: なし

---

## stop.sh

### stop_all()
- **目的**: kiro-team tmux セッションを kill する
- **入力**: なし
- **出力**: なし

---

## status.sh

### show_status()
- **目的**: 全エージェントのセッション生死と results/ の最終更新時刻を表示する
- **入力**: なし
- **出力**: 標準出力にステータス一覧

---

## watcher.sh

### watch_results()
- **目的**: results/ を POLL_INTERVAL 秒ごとに監視し、未通知の変更があり PdM がプロンプト待ちの場合のみ notify_pdm() を呼ぶ
- **入力**: なし
- **出力**: なし（常駐ループ）
- **判断ロジック**:
  1. results/<name>.md が前回から更新されているか（タイムスタンプ比較）
  2. .notified マークが存在しないか
  3. PdM セッションが capture-pane で PROMPT_PATTERN にマッチするか（プロンプト待ち）
  → 全て OK の場合のみ notify_pdm() を呼ぶ

### notify_pdm(agent_name)
- **目的**: PdM セッションに "[SYSTEM] <agent_name> updated results. Check results/<agent_name>.md" を send-keys し、results/<agent_name>.notified を作成する
- **入力**: agent_name（文字列）
- **出力**: なし

---

## notifier.sh

### watch_tasks()
- **目的**: tasks/ を POLL_INTERVAL 秒ごとに監視し、未送信タスクを検知したら deliver_task() を呼ぶ
- **入力**: なし
- **出力**: なし（常駐ループ）

### wait_for_prompt(agent_name)
- **目的**: tmux capture-pane で対象セッションの最終行を確認し、PROMPT_PATTERN にマッチするまで待機する
- **入力**: agent_name（文字列）
- **出力**: 0（成功）/ 1（タイムアウト）

### deliver_task(agent_name, task_content)
- **目的**: wait_for_prompt() 後に tmux send-keys でタスクを送信し、送信済みマーク（tasks/<agent_name>.sent）を作成する
- **入力**: agent_name（文字列）、task_content（文字列）
- **出力**: なし

### ensure_session(agent_name)
- **目的**: 対象エージェントの tmux ウィンドウが存在しない場合に作成し kiro-cli を起動する
- **入力**: agent_name（文字列）
- **出力**: なし
