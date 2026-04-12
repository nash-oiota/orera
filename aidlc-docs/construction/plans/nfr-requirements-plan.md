# NFR Requirements Plan — Unit 1: scripts & Unit 2: agent-configs

## 対象ユニット
- Unit 1: scripts（config.sh / start.sh / stop.sh / status.sh / watcher.sh / notifier.sh）
- Unit 2: agent-configs（pdm.json / frontend.json / backend.json / infra.json / qa.json）

---

## チェックリスト

- [ ] NFR 質問への回答収集
- [ ] Unit 1 の nfr-requirements.md を生成
- [ ] Unit 1 の tech-stack-decisions.md を生成
- [ ] Unit 2 の nfr-requirements.md を生成
- [ ] Unit 2 の tech-stack-decisions.md を生成

---

## 質問

### Question 1
スクリプトのエラー処理方針はどうしますか？（例: tmux コマンド失敗、kiro-cli が見つからない場合）

A) stderr にエラーメッセージを出力して終了（exit 1）
B) ログファイル（例: logs/kiro-team.log）に記録して終了
C) エラーを出力しつつ可能な限り続行する
D) Other (please describe after [Answer]: tag below)

[Answer]: 

---

### Question 2
`wait_for_prompt()` のタイムアウト時間はどうしますか？（プロンプトが検知できない場合の最大待機時間）

A) 30秒
B) 60秒
C) config.sh で設定可能にする
D) Other (please describe after [Answer]: tag below)

[Answer]: 

---

### Question 3
スクリプトの実行ログ（起動・停止・通知イベント）はどうしますか？

A) 不要（stderr のみ）
B) logs/kiro-team.log に記録する
C) tmux ウィンドウ内の出力のみ（ファイルログなし）
D) Other (please describe after [Answer]: tag below)

[Answer]: 
