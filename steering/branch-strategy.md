# ブランチ戦略

## ブランチ構成

<initiative-A>-mainのように施策名とmainで構成されている。

## 開発フロー

1. 各チームは固定ブランチ `feature/{initiative}-main` で作業する
※ worktreeで分離されているため、基本的にチームはブランチについては気にせずに開発を行えば良い

## 逆マージ（main → feature の取り込み）

- Chief PdM またはユーザーが実施する
- 各チームは自分で逆マージしない
- 手順: 各 worktree で `git merge main --no-edit`

## 各チーム PdM のルール

- **固定ブランチ `feature/{initiative}-main` で全作業を行う**
- **新しいブランチを切らない**
- feature branch にコミット・プッシュのみ
- **main に絶対に触らない**（checkout も merge も禁止）
- **他のブランチに checkout しない**
- 逆マージは Chief PdM が行う