# AGENTS.MD

Yasuhito がオーナー。開始時：挨拶 + やる気の出る一言。
作業スタイル：簡潔に。名詞句 OK。文法省略可。トークン最小化。

## クリティカルシンキング
- 常に正統的な修正を選ぶ。場当たりの hack は禁止。正統解が不明/困難なら必ず止めて相談。
- 根本原因を修正（場当たり対応ではなく）。
- 不明: もっとコードを読む。まだわからなければ、短い選択肢で質問。
- 衝突: 指摘して、より安全なパスを選択。
- 認識外の変更: 他のエージェントと想定。続行。自分の変更に集中。問題があれば止まってユーザーに確認。
- スレッドにパンくずメモを残す。

## エージェントプロトコル
- 連絡先: Yasuhito Takamiya (@yasuhito, yasuhito@hey.com)
- ワークスペース: `~/Work`。不足リポジトリ: `https://github.com/yasuhito/<repo>.git` から clone。
- サードパーティ/OSS（非 yasuhito）: `~/Work/oss` 以下に clone。
- `~/Work/manager`: プライベート運用（ドメイン/DNS、リダイレクト/workers、ランブック）。
- "macbook-pro" => そこに SSH。ホスト/IP は `tailscale status` で確認。
- ファイル: リポジトリ内 または `~/Work/agent-kit`。
- PR: `gh pr view/diff` を使用（URL 不要）。
- 「メモして」=> AGENTS.md を編集（ショートカット、ブロッカーではない）。`CLAUDE.md` は無視。
- `./runner` 不使用。ガードレール: 削除は `gio trash` を使用。
- 上流ファイルが必要: `/tmp/` にステージング後、cherry-pick。追跡済みファイルを上書きしない。
- バグ: 適切なら回帰テスト追加。
- ファイルは ~500 LOC 未満に。必要に応じて分割/リファクタ。
- コミット: Conventional Commits (`feat|fix|refactor|build|ci|chore|docs|style|perf|test`)。
- サブエージェント: `docs/subagent.md` を読む。
- エディタ: `code <path>`。
- CI: `gh run list/view`（green になるまで rerun/fix）。
- 可能なら end-to-end 検証。ブロックされたら不足を報告。
- 新しい依存: 軽くヘルスチェック（最近のリリース/コミット、採用状況）。
- スラッシュコマンド: `~/.codex/prompts/`。
- Web: 早めに検索。正確なエラーを引用。2024–2025 のソース優先。フォールバック Firecrawl (`pnpm mcp:*`) / `mcporter`。
- Oracle: 初回使用前に `npx -y @steipete/oracle --help` を1回実行。
- スタイル: 簡潔に。フィラー/文法省略。トークン最小化（グローバル AGENTS + 返信）。

## スクリーンショット（「スクショ使って」）
- `~/Pictures` または `~/Downloads` の最新 PNG を選択。
- 正しい UI か確認（ファイル名は無視）。
- サイズ確認: `file <file>` または `identify <file>`（ImageMagick）。
- アセット置換 → 寸法維持 → コミット → ゲート実行 → CI 確認。

## 重要な場所
- ブログリポジトリ: `~/Work/yasuhito.me`
- ノート/ランブック: `~/Work/manager/docs/`（例: `mac-studio.md`, `mac-vm.md`）
- OpenAI/Codex 制限追跡: `~/Documents/codex limits.md`
- Obsidian vault: `~/Work/obsidian`

## ドキュメント
- 開始時: `../agent-kit` で `bun build scripts/docs-list.ts --compile --outfile bin/docs-list` を必ず実行（存在確認不要）。
- その後 docs リストを実行（`docs:list` スクリプト、または `bin/docs-list`）。コーディング前にドキュメントを開く。
- `Read when` に一致したら、該当する `../agent-kit/docs/*.md` を必ず開いて読む。
- リンクを辿ってドメインを理解。`Read when` ヒントを尊重。
- ノートは短く。動作/API 変更時はドキュメント更新（ドキュメントなしでリリースしない）。
- クロスカッティングなドキュメントには `read_when` ヒントを追加。
- モデル優先: 最新のみ。OK: Anthropic Opus 4.5 / Sonnet 4.5（Sonnet 3.5 = 古い、避ける）、OpenAI GPT-5.2、xAI Grok-4.1 Fast、Google Gemini 3 Flash。

## PR フィードバック
- アクティブ PR: `gh pr view --json number,title,url --jq '"PR #\\(.number): \\(.title)\\n\\(.url)"'`
- PR コメント: `gh pr view …` + `gh api …/comments --paginate`
- 返信: 修正 + ファイル/行を引用。修正後のみスレッド解決。
- PR マージ時: `CHANGELOG.md` でコントリビューターに感謝。

## フロー & ランタイム
- リポジトリのパッケージマネージャ/ランタイムを使用。承認なしで変更しない。
- 長いジョブは Codex バックグラウンドで。tmux は対話/永続が必要な場合のみ（デバッガ/サーバー）。

## ビルド / テスト
- ハンドオフ前: フルゲート実行（lint/typecheck/tests/docs）。
- CI が赤: `gh run list/view`、rerun、fix、push、green まで繰り返し。
- 観察可能に（ログ、ペイン、tail、MCP/ブラウザツール）。
- リリース: `docs/RELEASING.md` を読む（なければ最適なチェックリストを探す）。
- リマインダー: `~/.profile` で不足 env キーを確認（例: `SPARKLE_PRIVATE_KEY_FILE`）。Sparkle キーは `~/Library/CloudStorage/Dropbox/Backup/Sparkle` にある。

## Git
- デフォルトは安全に: `git status/diff/log`。push はユーザーが求めた時のみ。
- `git checkout` は PR レビュー/明示的リクエスト時 OK。
- ブランチ変更はユーザー同意が必要。
- 破壊的操作は明示的でない限り禁止（`reset --hard`、`clean`、`restore`、`rm` など）。
- `~/Work` 以下のリモート: HTTPS 推奨。pull/push 前に SSH→HTTPS に変換。
- コミットヘルパー PATH 上: `committer`（bash）。リポジトリに `./scripts/committer` があればそれを使用。
- 予期しないものを削除/リネームしない。止まって確認。
- リポジトリ全体の一括置換スクリプト禁止。編集は小さく/レビュー可能に。
- 手動 `git stash` 避ける。Git が pull/rebase 時に自動スタッシュするのは OK（ヒント、ハードガードレールではない）。
- ユーザーがコマンドを入力したら（「pull して push」）、そのコマンドへの同意。
- 明示的でない限り amend しない。
- 大きなレビュー: `git --no-pager diff --color=never`。
- マルチエージェント: 編集前に `git status/diff` 確認。小さなコミットで ship。

## 言語/スタック メモ
- Swift: ワークスペースヘルパー/デーモン使用。`swift build` + テストを検証。concurrency 属性を正しく保つ。
- TypeScript: リポジトリの PM 使用。`docs:list` 実行。ファイルは小さく。既存パターンに従う。

## ツール

`~/Work/agent-kit/tools.md` が存在すればフルツールカタログを読む。

### bird
- X CLI: `bird`（npm グローバルインストール）。コマンド: `tweet`, `reply`, `read`, `thread`, `search`, `mentions`, `whoami`。

### omarchy スクリーンショット
- スクショ（編集付き）: `omarchy-cmd-screenshot`（PRINT キー）
- スクショをクリップボードへ: `omarchy-cmd-screenshot smart clipboard`（SHIFT + PRINT）
- 画面録画: `omarchy-cmd-screenrecord`（ALT + PRINT）
- カラーピッカー: `hyprpicker -a`（SUPER + PRINT）

### clone-oss
- OSS リポジトリを `~/Work/oss/` に clone。使い方: `clone-oss <repo-url> [name]`
- 例: `clone-oss https://github.com/danielmiessler/Personal_AI_Infrastructure PAI`

### committer
- コミットヘルパー（PATH）。リストしたパスのみステージング。リポジトリに `./scripts/committer` があればそれを使用。

### gio trash
- ファイルをゴミ箱へ移動: `gio trash <file>`（Linux）。

### bin/docs-list / scripts/docs-list.ts
- オプション。`docs/` をリスト + フロントマター強制。`bin/docs-list` がなければ無視。リビルド: `bun build scripts/docs-list.ts --compile --outfile bin/docs-list`。

### bin/browser-tools / scripts/browser-tools.ts
- Chrome DevTools ヘルパー。コマンド: `start`, `nav`, `eval`, `screenshot`, `pick`, `cookies`, `inspect`, `kill`。
- リビルド: `bun build scripts/browser-tools.ts --compile --target bun --outfile bin/browser-tools`。

### oracle
- 2 番目のモデル用にプロンプト+ファイルをバンドル。詰まった/バグ/レビュー時に使用。
- 初回使用前に `npx -y @steipete/oracle --help` を1回実行。

### mcporter / firecrawl
- MCP ランチャー: `mcporter`（グローバルインストール済）。
- firecrawl: Web スクレイピング。`mcporter call firecrawl.firecrawl_scrape url=https://example.com`
- 設定: `~/.mcporter/mcporter.json`, `~/.codex/mcp.json`, `~/.config/claude/claude_desktop_config.json`

### gh
- GitHub CLI（PR/CI/リリース用）。issue/PR URL があれば `gh` を使用、Web 検索不要。
- 例: `gh issue view <url> --comments -R owner/repo`、`gh pr view <url> --comments --files -R owner/repo`。

### スラッシュコマンド
- グローバル: `~/.codex/prompts/`。リポジトリローカル: `docs/slash-commands/`。
- よく使う: `/handoff`, `/pickup`。

### tmux
- 永続/対話が必要な時のみ使用（デバッガ/サーバー）。
- クイックリファレンス: `tmux new -d -s codex-shell`、`tmux attach -t codex-shell`、`tmux list-sessions`、`tmux kill-session -t codex-shell`。

<frontend_aesthetics>
「AI スロップ」UI を避ける。独自性を持つ。

やること:
- タイポグラフィ: 実際のフォントを選ぶ。Inter/Roboto/Arial/システムデフォルト回避。
- テーマ: パレットにコミット。CSS 変数使用。弱いグラデーションより大胆なアクセント。
- モーション: 1–2 のインパクトある瞬間（ランダムなマイクロアニメより段階的リビール）。
- 背景: 深みを追加（グラデーション/パターン）、フラットなデフォルトではなく。

避ける: 紫と白のクリシェ、汎用コンポーネントグリッド、予測可能なレイアウト。
</frontend_aesthetics>
