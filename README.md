# Agent Kit

AI エージェント用のスクリプト・スキル・ガードレール集。

## 構造

- `AGENTS.MD` - 共有ガードレール（他リポジトリからポインターで参照）
- `scripts/` - ヘルパースクリプト
- `skills/` - 再利用可能スキル
- `docs/` - ドキュメント
- `bin/` - コンパイル済みバイナリ

## 使い方

他のリポジトリの `AGENTS.MD` 先頭に追加：

```markdown
READ ~/Work/agent-kit/AGENTS.MD BEFORE ANYTHING (skip if missing).
```

## 運用メモ

- 定期実行（systemd timer）: `docs/operations/systemd-timer.md`
- Codex notify（AgentMem）: `docs/operations/codex-notify.md`

## AgentMem とは

AgentMem は、UOCS（Universal Output Capture System）パターンを Codex 向けに移植した
**作業成果の自動キャプチャ**仕組みです。主な特徴は次のとおりです。

- **Task の最終出力を自動保存**（SubagentStop 相当のタイミング）
- **Markdown + frontmatter** で構造化して保存
- **決定論的な保存先・命名規則**（検索/再利用しやすい）
- **失敗しても本流を止めない**（notify 連携の hook として動作）

保存先は `~/.agent-kit/MEMORY`（Claude/Codex 共通）で、カテゴリごとに分かれます。
詳細は `docs/operations/uocs-overview.md` と `docs/operations/codex-notify.md` を参照してください。
