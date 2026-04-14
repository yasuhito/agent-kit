---
name: oracle
description: '@steipete/oracle CLI でプロンプト + 適切なファイルを束ね、別モデルのレビュー（API またはブラウザ）を受ける。デバッグ、リファクタ、設計チェック、クロス検証に使う。'
---

# Oracle (CLI) — 使い方

Oracle はプロンプト + 選択したファイルを一つの「ワンショット」リクエストにバンドルし、別モデルが実際のリポジトリ文脈つきで回答できるようにする（API またはブラウザ自動化）。出力は助言として扱い、必ずコードベース + テストで検証すること。

## 主な使い方（ブラウザ、GPT-5.2 Pro）

ここでのデフォルトワークフローは `--engine browser` + GPT-5.2 Pro。これは「human-in-the-loop」の経路で、10 分〜 1 時間かかることがある。保存済みセッションに再アタッチできる前提で使う。

推奨デフォルト:
- エンジン: browser（`--engine browser`）
- モデル: GPT-5.2 Pro（`--model gpt-5.2-pro` または ChatGPT 側の picker 名 `--model "5.2 Pro"`）
- 添付: ディレクトリ/glob + 除外を使う。シークレットは添付しない。

## ゴールデンパス（高速 + 信頼性）

1. 真実を含む最小限のファイルセットを選ぶ
2. 送信前に `--dry-run` でプレビューする（必要なら `--files-report` も）
3. 通常の GPT-5.2 Pro ChatGPT ワークフローには browser を使う。API は明示的に必要な時だけ
4. 実行が detach / timeout したら再実行しない。保存済みセッションに再アタッチする

## コマンド（推奨）

- ヘルプ表示（最初に1回）:
  - `npm exec --yes --package @steipete/oracle -- oracle --help`

- プレビュー（トークン消費なし）:
  - `npm exec --yes --package @steipete/oracle -- oracle --dry-run summary -p "<タスク>" --file "src/**" --file "!**/*.test.*"`
  - `npm exec --yes --package @steipete/oracle -- oracle --dry-run full -p "<タスク>" --file "src/**"`

- トークン/コスト確認:
  - `npm exec --yes --package @steipete/oracle -- oracle --dry-run summary --files-report -p "<タスク>" --file "src/**"`

- ブラウザ実行（メイン経路。長時間は正常）:
  - `npm exec --yes --package @steipete/oracle -- oracle --engine browser --model gpt-5.2-pro -p "<タスク>" --file "src/**"`

- 手動ペーストフォールバック（バンドルを作り、クリップボードへコピー）:
  - `npm exec --yes --package @steipete/oracle -- oracle --render --copy -p "<タスク>" --file "src/**"`
  - `--copy` は `--copy-markdown` の hidden alias。

## ファイル添付（`--file`）

`--file` はファイル、ディレクトリ、glob を受け付ける。複数回指定でき、カンマ区切りも可能。

- 含める:
  - `--file "src/**"`（ディレクトリ glob）
  - `--file src/index.ts`（単一ファイル）
  - `--file docs --file README.md`（ディレクトリ + ファイル）

- 除外（`!` プレフィックス）:
  - `--file "src/**" --file "!src/**/*.test.ts" --file "!**/*.snap"`

- 実装上のデフォルト動作（重要）:
  - デフォルト除外ディレクトリ: `node_modules`, `dist`, `coverage`, `.git`, `.turbo`, `.next`, `build`, `tmp`
  - glob 展開時は `.gitignore` を尊重する
  - シンボリックリンクは追わない
  - ドットファイルは、パターン側で明示しない限り除外される（例: `--file ".github/**"`）
  - 1 MB を超えるファイルは拒否される（分割するかマッチを絞る）

## バジェット + 観測性

- 目標: 合計入力をおおむね 196k tokens 未満に保つ
- `--files-report`（必要なら `--dry-run json`）で、どのファイルが token を食っているか先に確認する
- 隠し/詳細オプションを見たい場合: `npm exec --yes --package @steipete/oracle -- oracle --help --verbose`

## エンジン（API vs ブラウザ）

- 自動選択: `OPENAI_API_KEY` があれば `api`、なければ `browser`
- browser engine は GPT + Gemini のみ対応。Claude / Grok / Codex / 複数モデルには `--engine api` を使う
- **API 実行は課金が発生するため、開始前にユーザーの明示同意が必要**
- browser attachments:
  - `--browser-attachments auto|never|always`（`auto` は約 60k chars までは inline paste、その後 upload）
- リモート browser host（サインイン済みマシンで自動化を動かす）:
  - Host: `npm exec --yes --package @steipete/oracle -- oracle serve --host 0.0.0.0 --port 9473 --token <secret>`
  - Client: `npm exec --yes --package @steipete/oracle -- oracle --engine browser --remote-host <host:port> --remote-token <secret> -p "<task>" --file "src/**"`

## セッション + slug（作業を失わない）

- セッション保存先: `~/.oracle/sessions`（`ORACLE_HOME_DIR` で変更可能）
- browser + GPT-5.2 Pro は長時間化しやすい。CLI が timeout しても再実行しないで再アタッチする
  - 一覧: `npm exec --yes --package @steipete/oracle -- oracle status --hours 72`
  - 再アタッチ: `npm exec --yes --package @steipete/oracle -- oracle session <id> --render`
- `--slug "<3-5 words>"` を使うとセッション ID が読みやすくなる
- 重複プロンプトのガードがある。本当に fresh run が必要な時だけ `--force` を使う

## プロンプトテンプレート（高信号）

Oracle は**プロジェクト知識ゼロ**で始まる。モデルがスタック、ビルドツール、慣習、パスを推測してくれると思わないこと。少なくとも以下を含める:
- プロジェクト概要（スタック + build/test コマンド + プラットフォーム制約）
- 「どこに何があるか」（主要ディレクトリ、エントリポイント、設定ファイル、依存境界）
- 正確な質問 + 試したこと + エラーテキスト（原文のまま）
- 制約（「X は変えない」「公開 API は維持」「perf budget」など）
- 欲しい出力（「patch plan + tests」「危険な仮定の列挙」「3 つの選択肢 + tradeoff」など）

### 長い調査向けの「exhaustive prompt」パターン

後で同じ調査を復元したくなると分かっている時は、そのまま再利用できるプロンプトを書く:
- 冒頭: 6〜30 文のプロジェクト概要 + 現在の目標
- 中盤: 具体的な再現手順 + 正確なエラー + 既に試したこと
- 末尾: fresh model が完全に理解するために必要な文脈ファイルを全部添付（entrypoints、config、主要 module、docs）

同じ文脈をあとで再現したい場合は、同じ prompt + `--file ...` セットで再実行する（Oracle は one-shot で、前回の会話を覚えていない）。

## 安全性

- デフォルトでシークレットを添付しない（`.env`、鍵ファイル、認証トークンなど）
- 「必要十分な文脈」を優先する。全リポジトリ投げより、少ないファイル + 良い prompt のほうがよい
- 共有が必要な箇所だけを赤入れ/墨消しして渡す
