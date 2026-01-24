---
summary: 'PR を一気にランド（changelog + thanks、lint、merge、main に戻る）'
read_when:
  - PR を accept する時: 修正、lint、merge、main 同期
---
# /acceptpr

入力: PR 番号または URL（必須）。デフォルトマージモード: rebase。

0) ガードレール
- 必ず `main`（または `main` がなければリポジトリのデフォルトブランチ）で終わる
- 前後で `git status -sb` がクリーン。コミットされていない変更なし
- PR がドラフト、コンフリクトあり、またはベースブランチが `main` でない場合: 停止して確認
- PR がフォークからで push できない場合: 停止して確認

1) コンテキスト取得
- `START_BRANCH="$(git branch --show-current)"`
- `gh pr view <PR> --json number,title,author,baseRefName,headRefName,isDraft,mergeable,maintainerCanModify`
- 概観: `gh pr view <PR> --comments` と `gh pr diff <PR>`

2) チェックアウト + 修正提案
- `gh pr checkout <PR>`
- 修正を適用（必要ならテストも）。編集は最小限に。リポジトリの規約に従う
- 変更/機能/リグレッションが十分にテストされていることを確認（テスト追加/拡張、グリーンになるまで最小限の関連テストを実行）
- 明示的パスでコミット（`git add .` 禁止）、その後プッシュ: `git push origin HEAD`

3) Changelog（コントリビューターに感謝）
- `CHANGELOG.md`（またはプロジェクトの changelog ファイル）を編集
- 先頭の "Unreleased" セクションにエントリを追加（既存スタイルに合わせる）
- PR + thanks を含める。例: `- <変更内容> (#<num>) — thanks @<author>`
- 変更があればコミット + プッシュ

4) Lint
- リポジトリの linter/gate を実行（既存スクリプト優先、グリーンになるまで修正）
- 明らかな lint ターゲットがなければ検索: `rg -n "lint|biome|eslint|swiftlint|ruff" package.json Makefile scripts -S`

5) マージ（その後 PR ブランチを削除）
- rebase マージ優先: `gh pr merge <PR> --rebase --delete-branch`
- rebase が禁止されている場合、リポジトリの設定に従う（`--merge` または `--squash`）

6) `main` を同期 + クリーンに終了
- `git checkout main || git checkout "$(git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@')"`
- `git pull --ff-only`
- マージ確認: `gh pr view <PR> --json mergedAt,mergeCommit`
- `git status -sb`（クリーン）+ `main` にいることを確認
