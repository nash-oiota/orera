# ブランチ戦略

## ブランチ構成

| ブランチ | 用途 | デプロイ |
|---|---|---|
| `main` | 本番環境 | Cloudflare Pages が自動デプロイ（https://nyuumon.pages.dev） |
| `develop` | 開発統合ブランチ | Cloudflare Pages プレビュー環境 |
| `feature/*` | 機能開発 | なし |

## 開発フロー

1. PdM が `develop` から `feature/xxx` または `fix/xxx` ブランチを作成する
2. AI開発者（frontend / backend / infra / qa）は全員同じ feature ブランチで作業する
3. 実装・テスト完了を PdM が判断し、ユーザーにコードレビューを求める

## ルール

- `main` への直接 push は禁止
- AI開発者は指定された feature ブランチで作業し、直接 `develop` や `main` には push しない
- コミットメッセージは日本語でも英語でも OKだが、ConventionalCommitsの方式でコミットする
- feature ブランチ名の例：`feature/add-lesson7`、`fix/breadcrumb-link`
