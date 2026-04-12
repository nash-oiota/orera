# NFR Design Patterns — Unit 2: agent-configs

## 最小権限パターン（allowedTools）

全エージェントに必要なツールのみを `allowedTools` に列挙。ユーザー確認なしで実行できる範囲を明示的に制限。

```json
{
  "allowedTools": ["execute_bash", "fs_write", "fs_read"]
}
```

## Fail-Safe デフォルトパターン（プロンプト設計）

不明な状況・判断できない場合は `STATUS: BLOCKED` で PdM に報告するルールをプロンプトに明記。
エラー時に勝手に推測して進まない設計。

## 責務分離パターン（PdM / specialist）

- PdM: 判断・委任・マネジメント（実装しない）
- specialist: 実装・報告（判断しない）

プロンプトで役割境界を明確に定義し、責務の混在を防ぐ。

## スコープ制限パターン（specialist）

専門領域外のタスクは `STATUS: QUESTION` で PdM に確認を求めるルールをプロンプトに明記。
specialist が権限外の判断をしない設計。
