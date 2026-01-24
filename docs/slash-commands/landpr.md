---
summary: 'スラッシュコマンド: /landpr プロンプトテンプレート'
read_when:
  - PR を一気にランドする時（rebase temp branch、changelog、gate、merge）
---
# /landpr

入力
- PR: `<pr-number>`

実行（一気通貫）
目標: PR が GitHub 状態 `MERGED`（`CLOSED` ではない）で終わる。`gh pr merge` を `--rebase` または `--squash` で使用。

1) リポジトリクリーン: `git status`
2) PR メタ情報取得（author + head branch）:
   - `gh pr view <pr-number> --json number,title,author,headRefName,baseRefName --jq '{number,title,author:.author.login,head:.headRefName,base:.baseRefName}'`
   - `contrib=$(gh pr view <pr-number> --json author --jq .author.login)`
   - `head=$(gh pr view <pr-number> --json headRefName --jq .headRefName)`
3) ベースを fast-forward:
   - `git checkout main`
   - `git pull --ff-only`
4) `main` から temp ベースブランチ作成:
   - `git checkout -b temp/landpr-<pr-number>`
5) PR ブランチをローカルにチェックアウト:
   - `gh pr checkout <pr-number>`
6) PR ブランチを temp ベースに rebase:
   - `git rebase temp/landpr-<pr-number>`
   - コンフリクト解決、履歴を整理
7) 修正 + テスト + changelog:
   - 修正を実装 + テスト追加/調整
   - `CHANGELOG.md` を更新、`#<pr-number>` + `@$contrib` を記載
8) マージ戦略を選択（不明なら確認）:
   - Rebase: コミット履歴を保持
   - Squash: 単一のクリーンなコミット
9) フルゲート（コミット前）:
   - `pnpm lint && pnpm build && pnpm test`
10) `committer` でコミット（`#<pr-number>` + contributor をメッセージに含める）:
   - `committer "fix: <summary> (#<pr-number>) (thanks @$contrib)" CHANGELOG.md <changed files>`
   - `land_sha=$(git rev-parse HEAD)` をキャプチャ
11) 更新した PR ブランチを push（rebase => 通常 force が必要）:
   - `git push --force-with-lease`
12) PR をマージ（GitHub で MERGED 表示が必須）:
   - Rebase: `gh pr merge <pr-number> --rebase`
   - Squash: `gh pr merge <pr-number> --squash`
   - `gh pr close` は絶対使わない
13) `main` を同期 + push:
   - `git checkout main`
   - `git pull --ff-only`
   - `git push`
14) PR にコメント（実行内容 + SHA + thanks）:
   - `merge_sha=$(gh pr view <pr-number> --json mergeCommit --jq '.mergeCommit.oid')`
   - `gh pr comment <pr-number> --body "Landed via temp rebase onto main.\n\n- Gate: pnpm lint && pnpm build && pnpm test\n- Land commit: $land_sha\n- Merge commit: $merge_sha\n\nThanks @$contrib!"`
15) PR 状態 == `MERGED` を確認:
   - `gh pr view <pr-number> --json state,mergedAt --jq '.state + \" @ \" + .mergedAt'`
16) temp ブランチを削除:
   - `git branch -D temp/landpr-<pr-number>`
