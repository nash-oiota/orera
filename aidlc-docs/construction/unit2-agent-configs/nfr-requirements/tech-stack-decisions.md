# Tech Stack Decisions — Unit 2: agent-configs

## フォーマット

| 項目 | 決定 | 理由 |
|---|---|---|
| 設定フォーマット | JSON | kiro-cli のエージェント設定形式 |
| プロンプト管理 | JSON `prompt` フィールドに直接記述 | 外部ファイル参照が kiro-cli でサポートされているか未確認 |

## エージェント権限（allowedTools）

| エージェント | allowedTools | 備考 |
|---|---|---|
| pdm | execute_bash, fs_write, fs_read | tmux 操作・tasks/ 書き込み・status.sh 実行 |
| frontend | execute_bash, fs_write, fs_read | 実装作業・results/ 書き込み |
| backend | execute_bash, fs_write, fs_read | 同上 |
| infra | execute_bash, fs_write, fs_read | 同上 |
| qa | execute_bash, fs_write, fs_read | 同上 |

初期は網羅的に設定し、運用しながら不要な権限を絞る方針。
