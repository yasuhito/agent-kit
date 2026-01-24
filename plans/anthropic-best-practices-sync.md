# Anthropic Best Practices 巡回・差分・反映システム

## 決まったこと
- 更新対象: このプロジェクトの `docs/*.md`。
- 正とする情報源: まずは Anthropic 公式ドキュメントを優先。
- 参考情報源: 社員のツイート/ブログ等も参考候補（優先度は公式より下）。
- 目標: コード中心・決定論的・コンテキスト非依存で動く仕組み。

## 未決
- 自動反映の範囲（公式のみ/軽微変更のみ自動適用 vs 全てレビュー必須）。
- 使用ランタイム（bun/node/python）。
- 公式ドキュメントの具体URL一覧（sources.yaml など）。

## 追加決定
- まずは `docs/best-practices/*.md` を新規作成し、テーマ別（例: スキルの書き方、CLAUDE.md の書き方など）に分割する。
- 初期テーマ: CLAUDE.md の書き方。
- 初期は sources.yaml を手作業で起こして開始し、後で公式サイトの sitemap/RSS/Changelog から新規URL候補を自動抽出する仕組みに拡張する。
- 実装場所: /home/yasuhito/Work/agent-kit
- ランタイム: Ruby
- 作成: docs/best-practices/ ディレクトリ
- 方針: AIが骨子を作らない。まずは Anthropic 公式 docs を決定論的に取得するための取得ツールを作る。
- 取得ツール作成: scripts/anthropic_fetch.rb
- データ保存先: data/anthropic/ (sources.yaml, state.json, snapshots/)
- メモ: add-skill CLI の利用を検討。後回し。
- 正規化: pandoc を使用。scripts/anthropic_normalize.rb 追加。
- 正規化MarkdownをH2単位で分割し、index.md + 連番セクション.md を生成する方針。
- 分割ツール作成: scripts/anthropic_split_sections.rb
- 公式Docsは .md エンドポイントを優先して取得する（例: /best-practices.md）。HTMLはフォールバック。
- CLAUDE.md 用抽出スクリプト作成: scripts/anthropic_generate_claude_md.rb
- 出力する best-practices の .md は日本語で生成する。
- 翻訳は GPT-5 を使用。英語生成後に翻訳を適用し、docs/ に日本語を出力。
- 翻訳スクリプト追加: scripts/openai_translate_markdown.rb
- 説明ドキュメント追加: plans/anthropic-best-practices-pipeline.md
- 翻訳スクリプトに --use-1password を追加。tmux 内で op read して OPENAI_API_KEY を取得。
- GPT-5 では temperature が使えないため、翻訳スクリプトから温度指定を省略（必要時のみ --temperature で指定）。
