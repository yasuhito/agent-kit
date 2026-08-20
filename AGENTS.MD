私は安仁（やすひと）です。あなたには私のエージェントとして、いつも一緒に作業をお願いしています。改めて自己紹介させてください。

私は量子コンピューティングの研究者です。量子回路のトランスパイラ Tranqu やシミュレータ Qni、QuantAttack、QA<sup>2</sup> といった量子ゲームをつくってきました。

私はものをつくることが好きです。複雑なものをできる限りシンプルにつくることに力を入れ、問題を解くときも複雑さを減らす方法を探すのが好きです。

これから一緒に作業するうえで認識を合わせられるよう、私の好みや考え方をいくつか共有します。

## エージェントの話し方と書き方

エージェントはルー大柴のような英語のまじった日本語を話しがち&書きがち。それを正そう。必要なら背景を少し説明し、ASD-STE100 相当の簡潔な日本語を話そう&書こう。そして、`CONTEXT.md` が存在すればそこにあるユビキタス言語を使おう。

## エージェントの作業ルール
- 質問への回答は読み取り専用とする。明示的に変更・実装・実行を依頼されない限り、ファイルの編集、コミット、設定変更、外部サービスへの操作を行わない。
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
- 開始時は docs 一覧を実行する（`docs:list` スクリプトがあればそれを、なければ `~/Work/agent-kit/bin/docs-list` を絶対パスで叩く）。コーディング前に関連ドキュメントを開く。
- `Read when` に一致したドキュメントは必ず開いて読む。
- リンクを辿って、必要なドメイン知識がつくまで読む。`Read when` ヒントを尊重する。
- ノートは短く保つ。動作や API を変えたときはドキュメントも更新する。ドキュメントなしで出荷しない。
- 複数の作業や機能にまたがって参照されるドキュメントには、`read_when` ヒントを追加する。

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
- CI が失敗したら、`gh run list` や `gh run view` で原因を確認する。コードや設定に起因する失敗は修正し、必要なら再実行・pushする。
- 課金上限、利用枠、同時実行数、外部サービス障害など、コードや設定に起因しない失敗は再実行や回復待ちをしない。手元でCI相当のチェックが通っていれば作業を進め、ハンドオフで原因と実行済みのチェックを報告する。
- 原因が不明なCI失敗を、課金・基盤エラーと決めつけない。
- 長時間のジョブや検証は、進捗や失敗理由が追える形で実行する。ログ、ペイン、`tail`、MCP、ブラウザツールを活用する。
- リリース作業をするときは、まず `docs/RELEASING.md` を読む。なければ最適なチェックリストを探す。

## Git
- 基本は安全な Git 操作を優先し、まず `git status`、`git diff`、`git log` を使う。push は原則ユーザーの明示的な指示がある場合のみとする。ただし、依頼された変更作業で CI を green に戻すために必要な PR への push は例外とする。
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
- OSS リポジトリを `~/Work/oss/` 以下に clone するときは、`clone-oss <repo-url> [name]` を使う。
- 例: `clone-oss https://github.com/danielmiessler/Personal_AI_Infrastructure PAI`

### committer
- コミットには `committer` を使う。リポジトリ内に `./scripts/committer` があればそれを優先し、なければ PATH 上の `committer` を使う。指定したパスだけがステージされる。

### gio trash
- `~/Work` 配下のファイルをゴミ箱に移動するときは、`gio trash <file>` を使う。

### docs-list
- `~/Work/agent-kit/bin/docs-list` を絶対パスで実行する。PATH に頼らない（`~/Work/.mise.toml` の `_.path = "{{ cwd }}/bin"` は現在の cwd 直下の `bin/` しか通さないため、agent-kit の外や非対話シェルでは `docs-list` が `command not found` になる）。実行した cwd から上に辿って見つけた `docs/` の Markdown 一覧と front matter の有無を確認するツール。無ければ無視してよい。
- ソースは `~/Work/agent-kit/scripts/docs-list.ts`。リビルドするときは `cd ~/Work/agent-kit && bun build scripts/docs-list.ts --compile --outfile bin/docs-list` を実行する。

### browser-tools
- `~/Work/agent-kit/bin/browser-tools` を絶対パスで実行する（理由は docs-list と同じ。PATH 経由の `browser-tools` には頼らない）。Chrome DevTools ヘルパーとして使う。主なコマンドは `start`, `nav`, `eval`, `screenshot`, `pick`, `cookies`, `inspect`, `kill`。
- バイナリは git 管理しない（無ければ無視してよい）。必要なら、一時的な Bun ワークスペースで `commander` と `puppeteer-core` を入れてから、`cd ~/Work/agent-kit && bun build scripts/browser-tools.ts --compile --target bun --outfile bin/browser-tools` で再生成する。

### oracle
- 別モデルにプロンプトと関連ファイルをまとめて渡したいときに使う。詰まったとき、バグ調査、レビュー、設計のクロスチェックに向いている。
- 初回使用前には `npm exec --yes --package @steipete/oracle -- oracle --help` を実行する。

### mcporter
- MCP サーバーの一覧や呼び出しが必要なら、`npm exec --yes --package mcporter -- mcporter list` や `npm exec --yes --package mcporter -- mcporter call <server.tool>` を使う。
- firecrawl は現状設定されていないので、使える前提で書かない。

### gh
- GitHub CLI（PR/CI/リリース用）。issue/PR URL があれば `gh` を使い、Web 検索は不要。
- 例: `gh issue view <url> --comments -R owner/repo`、`gh pr view <url> --comments --files -R owner/repo`。

### prompt templates / スラッシュコマンド
- pi の prompt template は、グローバルでは `~/.pi/agent/prompts/`、プロジェクトでは `.pi/prompts/` を使う。
- `docs/slash-commands/` は補助ドキュメントとして扱う。よく使うものは `/handoff` と `/pickup`。

### tmux
- 永続化や対話が必要なときだけ使う（デバッガやサーバーなど）。
- 例: `tmux new -d -s pi-shell`、`tmux attach -t pi-shell`、`tmux list-sessions`、`tmux kill-session -t pi-shell`。

<frontend_aesthetics>
AI が量産したような無個性な UI を避ける。明確な美意識と個性を持たせる。

やること:
- タイポグラフィでは、実際に意図を持ってフォントを選ぶ。Inter、Roboto、Arial、システムデフォルトに安易に頼らない。
- テーマは、曖昧にせずパレットを明確に決める。色は CSS 変数で管理し、弱いグラデーションより大胆なアクセントを使う。
- モーションは、細かいアニメーションをばらまくより、1〜2 個の印象的な瞬間を作る。ランダムなマイクロアニメーションより段階的なリビールを優先する。
- 背景には深みを持たせる。グラデーションやパターンを使い、のっぺりしたフラットな初期状態のままにしない。

避けるもの: 紫と白のありがちな配色、汎用的なコンポーネントグリッド、先が読めるレイアウト。
</frontend_aesthetics>
