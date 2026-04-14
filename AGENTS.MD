# AGENTS.MD

Yasuhito がオーナー。開始時は挨拶し、ひとこと前向きな言葉を添える。
作業スタイル：電報っぽく短く簡潔に。体言止め可。文法は崩してよい。トークン最小化。

## エージェントの作業ルール
- 連絡先: Yasuhito Takamiya (@yasuhito, yasuhito@hey.com)
- 作業場所は `~/Work`。不足している yasuhito 配下のリポジトリは `https://github.com/yasuhito/<repo>.git` から clone する。
- yasuhito 配下ではないサードパーティや OSS のリポジトリは `~/Work/oss` 以下に clone する。
- `~/Work/manager` はプライベート運用のためのリポジトリ（ドメイン/DNS、転送設定、Cloudflare Workers、運用手順書）。
- 「mac」と言われたら、そのマシンに SSH する。ホスト名や IP は `tailscale status` で確認する。
- ファイルは、現在のリポジトリ内または `~/Work/agent-kit` にあるものを使う。
- PR の確認には `gh pr view` や `gh pr diff` を使う。URL を直接たどらなくてよい。
- 「メモして」と言われたら、作業中のリポジトリの `AGENTS.md` を更新する。`CLAUDE.md` は無視してよい。
- 削除が必要なときは、`~/Work` 配下のファイルでは `gio trash` を使う。
- upstream や別のリポジトリからファイルを取り込む必要があるときは、いったん `/tmp/` に置いてから cherry-pick する。追跡済みファイルを直接上書きしない。
- バグ修正では、適切な場合は回帰テストを追加する。
- ファイルはおおむね 500 行未満に保つ。必要に応じて分割やリファクタを行う。
- コミットメッセージは Conventional Commits（`feat|fix|refactor|build|ci|chore|docs|style|perf|test`）に従う。
- サブエージェントを使うときは `docs/subagent.md` を読む。
- エディタを開く必要があるときは `emacsclient -n <path>` を使う。必要に応じて `emacs <path>` でもよい。
- CI の確認には `gh run list` や `gh run view` を使う。失敗していたら、green になるまで rerun と修正を繰り返す。
- 可能なら end-to-end で検証する。ブロックされた場合は、足りない認証情報・環境・依存サービス・権限を具体的に報告する。
- 新しい依存を追加するときは、最近のリリース頻度・コミット頻度・採用状況を軽く確認する。
- pi の prompt template は、グローバルでは `~/.pi/agent/prompts/`、プロジェクトでは `.pi/prompts/` を使う。
- Web 検索は早めに行い、正確なエラーメッセージを引用する。2025–2026 年のソースを優先する。必要なら pi の `web_search` / `fetch_content` / `mcp` を使う。
- Oracle を初めて使う前に、`npm exec --yes --package @steipete/oracle -- oracle --help` を1回実行する。
- 文体は簡潔にし、不要な前置きやフィラーを避ける。必要なら文法は少し崩してよい。返信も含めてトークンを最小化する。

## スクリーンショット（「スクショ使って」）
- 「スクショ使って」と言われたら、まず `~/Pictures` または `~/Downloads` にある最新の PNG を確認する。
- ファイル名ではなく実際の画像内容を見て、目的の UI かどうかを確認する。
- サイズは `file <file>` または `identify <file>`（ImageMagick）で確認し、可能なら高解像度の画像を優先する。
- PNG を最適化するときは、`magick <file> -strip -define png:compression-level=9 <output.png>` を使う。
- アセットを置き換えるときは、寸法を維持したうえでコミットし、必要なチェックを実行して CI も確認する。

## 重要な場所
- ブログリポジトリ: `~/Work/yasuhito.me`
- ノートや運用手順書は `~/Work/manager/docs/` にある（例: `mac-studio.md`, `mac-vm.md`）。
- 人間用の Obsidian vault は `~/Work/obsidian`。
- エージェント用の vault は `~/Work/AgentVault`。

## ドキュメント
- 開始時は docs 一覧を実行する（`docs:list` スクリプト、または `bin/docs-list` があればそれを使う）。コーディング前に関連ドキュメントを開く。
- `Read when` に一致したドキュメントは必ず開いて読む。
- リンクを辿って、必要なドメイン知識がつくまで読む。`Read when` ヒントを尊重する。
- ノートは短く保つ。動作や API を変えたときはドキュメントも更新する。ドキュメントなしで出荷しない。
- 複数の作業や機能にまたがって参照されるドキュメントには、`read_when` ヒントを追加する。
- 使うモデルは GPT-5.4 のみ。ほかのモデルへ勝手に切り替えない。

## PR フィードバック
- 現在のブランチに対応する PR を確認するときは、`gh pr view --json number,title,url --jq '"PR #\\(.number): \\(.title)\\n\\(.url)"'` を使う。
- PR のコメントを確認するときは、`gh pr view ...` と `gh api .../comments --paginate` を使う。
- PR コメントに返信するときは、何を直したかと対象のファイル/行を示す。修正が入る前にスレッドを解決しない。
- PR をマージするときは、`CHANGELOG.md` でコントリビューターに感謝を記す。
- PR や issue のタイトル・説明文は、このリポジトリの既存の PR / issue の言語とスタイルに合わせる。判断材料がなければユーザーに確認する。

## 作業の進め方と実行環境
- パッケージマネージャやランタイムは、そのリポジトリで使われているものを使う。承認なしに別のものへ切り替えない。
- 長時間かかるジョブはバックグラウンド実行を使う。`tmux` は対話や永続化が必要な場合だけ使う（デバッガやサーバーなど）。

## ビルド / テスト
- ハンドオフ前には、そのリポジトリで定義されているフルチェックを実行する（lint、typecheck、tests、docs など）。
- CI が失敗していたら、`gh run list` や `gh run view` で状況を確認し、green になるまで rerun・修正・push を繰り返す。
- 長時間のジョブや検証は、進捗や失敗理由が追える形で実行する。ログ、ペイン、`tail`、MCP、ブラウザツールを活用する。
- リリース作業をするときは、まず `docs/RELEASING.md` を読む。なければ最適なチェックリストを探す。

## Git
- 基本は安全な Git 操作を優先し、まず `git status`、`git diff`、`git log` を使う。push は原則ユーザーの明示的な指示がある場合のみとする。ただし、CI を green に戻すために必要な PR への push は例外とする。
- `git checkout` は、PR レビューまたはユーザーの明示的な依頼がある場合に使ってよい。
- ブランチを切り替えたり変更したりする前に、ユーザーの同意を取る。
- 破壊的な操作は、明示的な指示がない限り行わない（`git reset --hard`、`git clean`、`git restore`、`git rm` など）。
- `~/Work` 配下のリモートは HTTPS を優先する。pull や push の前に SSH URL を HTTPS に直せるなら直す。
- コミットヘルパーは、リポジトリ内に `./scripts/committer` があればそれを優先し、なければ PATH 上の `committer` を使う。
- 予期しないファイルや変更を勝手に削除・改名しない。必要なら止まってユーザーに確認する。
- リポジトリ全体に対する一括置換スクリプトは使わない。編集は小さく、レビューしやすい単位に保つ。
- 手動の `git stash` は避ける。pull や rebase の過程で Git が自動スタッシュするのは許容する。
- ユーザーが具体的な Git コマンドを指示した場合（例: 「pull して push」）、そのコマンドの実行については同意があるものとみなす。
- `git commit --amend` は、明示的に求められたときだけ使う。
- 大きな差分を確認するときは、`git --no-pager diff --color=never` を使う。
- 複数エージェントで作業するときは、編集前に `git status` と `git diff` を確認し、コミットは小さく分ける。

## 言語/スタック メモ
- TypeScript を扱うときは、そのリポジトリで使われているパッケージマネージャを使う。`docs:list` を実行し、ファイルは小さく保ち、既存のパターンに従う。

## ツール

`~/Work/agent-kit/tools.md` があれば、ツール一覧の参考として読む。

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
