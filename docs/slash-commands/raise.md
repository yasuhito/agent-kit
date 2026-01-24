---
summary: 'CHANGELOG.md に次のパッチ Unreleased セクションを作成（commit + push）'
read_when:
  - リリースを切った後、次のパッチサイクルを開始する時
---
# /raise

目標: `CHANGELOG.md` のトップリリースが日付付き（`Unreleased` ではない）なら、次のパッチバージョン用の新しいトップセクションを `Unreleased` として作成し、`CHANGELOG.md` **のみ** をコミット + プッシュ。

0) ガードレール
- `main`（またはリポジトリデフォルト）にいて `git status -sb` がクリーン
- `CHANGELOG.md` が既に `## <version> — Unreleased` で始まっている場合: 停止（何もしない）
- トップの `##` バージョンが `X.Y.Z` としてパースできない場合: 停止して確認

1) 次のパッチを計算
- `CHANGELOG.md` で最初のヘッダーを探す: `## X.Y.Z — <date|Unreleased>`
- サフィックスが日付（リリース済み）なら、パッチをバンプ: `X.Y.(Z+1)`

2) changelog を編集
- トップに挿入（最後にリリースされたセクションの上）:
  - `## X.Y.(Z+1) — Unreleased`
  - 空行
- 他のリリースセクションは触らない

3) コミット + プッシュ
- `committer "docs(changelog): start X.Y.(Z+1) cycle" CHANGELOG.md`
- `git push`

4) CI を確認
- `GH_PAGER=cat gh run list -L 5 --branch main --json status,conclusion,workflowName,displayTitle,updatedAt`
- いずれかの実行が失敗したら: `gh run view <id> --log`、修正、コミット、プッシュ、繰り返す
