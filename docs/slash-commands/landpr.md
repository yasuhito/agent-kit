---
summary: 'PR を temp branch rebase + full gate で一気にランドする'
read_when:
  - PR を一気にランドする時（rebase temp branch、full gate、merge）
---
# /landpr

入力
- PR: `$1`（番号または URL）。省略時は会話中の最新 PR を使う。曖昧なら確認。

目標
- GitHub 上の PR 状態を `MERGED` にする（`CLOSED` で終わらせない）。

0) ガードレール
- `git status -sb` がクリーンであること。
- PR が draft、コンフリクトあり、または head branch へ push できない場合は停止して確認。
- base はリポジトリのデフォルトブランチを優先する（多くは `main`）。

1) PR コンテキストを取得

```sh
PR="$1"
gh pr view "$PR" --json number,title,state,isDraft,mergeable,author,baseRefName,headRefName,headRepository,maintainerCanModify --jq '{number,title,state,isDraft,mergeable,author:.author.login,base:.baseRefName,head:.headRefName,headRepo:.headRepository.nameWithOwner,maintainerCanModify}'
prnum=$(gh pr view "$PR" --json number --jq .number)
contrib=$(gh pr view "$PR" --json author --jq .author.login)
base=$(gh pr view "$PR" --json baseRefName --jq .baseRefName)
head=$(gh pr view "$PR" --json headRefName --jq .headRefName)
head_repo_url=$(gh pr view "$PR" --json headRepository --jq .headRepository.url)
```

2) base を更新して temp ブランチ作成

```sh
git checkout "$base"
git pull --ff-only
git checkout -b "temp/landpr-$prnum"
```

3) PR を checkout して temp に rebase

```sh
gh pr checkout "$PR"
git rebase "temp/landpr-$prnum"
```

4) 修正 + テスト + changelog
- 修正を実装する（スコープは絞る）。
- 必要ならテストを追加/調整する（回帰テスト優先）。
- `CHANGELOG.md` を更新し、`#$prnum` と `@$contrib` を含める。

5) Gate（コミット前）
- リポジトリの full gate を実行する（lint/typecheck/tests/docs）。例: `pnpm lint && pnpm build && pnpm test`。

6) `committer` でコミット

```sh
committer "fix: <summary> (#$prnum) (thanks @$contrib)" CHANGELOG.md <changed files>
land_sha=$(git rev-parse HEAD)
```

7) rebase 済み PR ブランチを push（fork-safe）

```sh
git remote add prhead "$head_repo_url.git" 2>/dev/null || git remote set-url prhead "$head_repo_url.git"
git push --force-with-lease prhead "HEAD:$head"
```

8) PR をマージ
- Rebase: `gh pr merge "$PR" --rebase`
- Squash: `gh pr merge "$PR" --squash`
- `gh pr close` は使わない。

9) base をローカルで同期

```sh
git checkout "$base"
git pull --ff-only
```

10) SHA + thanks を PR コメントに残す

```sh
merge_sha=$(gh pr view "$PR" --json mergeCommit --jq '.mergeCommit.oid')
gh pr comment "$PR" --body "Landed via temp rebase onto $base.

- Gate: <cmds>
- Land commit: $land_sha
- Merge commit: $merge_sha

Thanks @$contrib!"
```

11) 状態が `MERGED` であることを確認

```sh
gh pr view "$PR" --json state,mergedAt --jq '.state + " @ " + .mergedAt'
```

12) Cleanup

```sh
git branch -D "temp/landpr-$prnum"
```
