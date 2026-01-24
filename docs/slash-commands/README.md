---
summary: 'スラッシュコマンド（プロンプト）のインデックスと配置場所'
read_when:
  - スラッシュコマンドのドキュメントを確認・更新する時
---
# スラッシュコマンド

スラッシュコマンドは `~/.codex/prompts/`（グローバル）と、存在する場合はリポジトリローカルフォルダ（例: `.claude/commands/`, `.cursor/commands/`）に配置される再利用可能なプロンプトテンプレート。

## 利用可能なコマンド

- `/acceptpr` — PR を一気にランド（changelog + thanks、lint、merge、main に戻る）
- `/handoff` — 次のエージェント用に現在の状態をキャプチャ（実行中セッション、tmux ターゲット、ブロッカー、次のステップ）
- `/landpr` — temp-branch rebase + フルゲート（`pnpm lint && pnpm build && pnpm test`）経由で PR をランド。`gh pr merge`（rebase/squash）でマージし、GitHub 状態が `MERGED`（`CLOSED` ではない）ことを確認
- `/pickup` — 作業開始時にコンテキストを再構築（status、tmux セッション、CI/PR 状態）
- `/raise` — changelog がリリース済みなら、次のパッチ `Unreleased` セクションを開く（`CHANGELOG.md` をコミット + プッシュ）

詳細は各ファイルを参照。
