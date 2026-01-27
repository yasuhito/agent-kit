# AgentMem 設計（UOCS パターン準拠）

## 目的

- サブエージェント/タスクの最終出力を **自動で履歴保存**する。
- 出力を **構造化 Markdown** として保存し、検索・再利用可能にする。
- 実行は **フック/自動処理** として動き、失敗しても本流を壊さない。

## 基本方針（UOCS そのまま）

- トリガ: **Codex notify の `agent-turn-complete`**（SubagentStop 相当）
- 入力: transcript（JSONL）から Task の tool_result を抽出
- 出力: `MEMORY/<CATEGORY>/<YYYY-MM>/` 配下に Markdown 保存
- 形式: frontmatter + 見出し + 本文 + メタ情報
- 失敗時: **黙って失敗**（ログのみ、プロセスは exit 0）

## 保存先（決定）

- ルート: `~/.agent-kit/MEMORY`（Claude/Codex 共通）
- 例: `~/.agent-kit/MEMORY/RESEARCH/2026-01/2026-01-25-091200_AGENT-researcher_RESEARCH_xxx.md`

※ 実行環境に依存しないよう、**ルートは設定可能**にする（ENV か config）。

## ファイル命名規則（UOCS 準拠）

```
YYYY-MM-DD-HHMMSS_AGENT-<type>_<CATEGORY>_<description>.md
```

- `CATEGORY`: RESEARCH / DECISION / IMPLEMENTATION / DESIGN / SECURITY …
- `description`: completion message を kebab-case で 60 字以内

## 出力フォーマット（UOCS 準拠）

```markdown
---
capture_type: RESEARCH
timestamp: 2026-01-25 09:12:00 JST
executor: researcher
agent_completion: Researcher completed ...
transcript_path: /path/to/transcript.jsonl
---

# RESEARCH: Researcher completed ...

**Agent:** researcher
**Completed:** 2026-01-25 09:12:00 JST

---

## Agent Output

<task output>

---

## Metadata

**Transcript:** `/path/to/transcript.jsonl`
**Captured:** 2026-01-25 09:12:00 JST
```

## 分類ルール（UOCS 準拠）

- agentType が `researcher` → RESEARCH
- `architect` → DECISION
- `engineer` → IMPLEMENTATION
- `designer` → DESIGN
- `pentester` → SECURITY
- それ以外 → RESEARCH

## 抽出ルール（UOCS 準拠）

- transcript JSONL を後ろから走査
- Task tool_use → tool_result を対応づけ
- 完了メッセージは新旧パターンに対応
  - `🗣️ AgentName: ...`
  - `🎯 COMPLETED: [AGENT:type] ...`

## Codex notify 連携（追記）

- `notify = ["python3", "/path/to/notify.py"]` のように **外部コマンドを登録**する。
- `notify` は **JSON を 1 つの引数として渡す**（`type: agent-turn-complete`）。
- `data` 内に `cwd`, `input-messages`, `last-assistant-message`, `thread-id`, `turn-id` が入る。

> ここでは `notify.py` を AgentMem の thin wrapper にして、JSON を保存対象に整形する。

## 実装方針（案）

- `scripts/` に **AgentMem hook** を追加
- フック呼び出し点は **Codex notify**（`agent-turn-complete`）
- 観測/通知は後回し（必要なら別スクリプト）

## 実装（進行中）

- スクリプト: `scripts/agentmem_notify.rb`
- 設定例: `notify = ["ruby", "/home/yasuhito/Work/agent-kit/scripts/agentmem_notify.rb"]`
- 環境変数:
  - `AGENTMEM_ROOT`（保存先ルート、既定 `~/.agent-kit/MEMORY`）
  - `AGENTMEM_DEBUG`（エラーを stderr に出す）
  - `CODEX_SESSIONS_DIR`（セッション JSONL ルート、既定 `~/.codex/sessions`）
- 取得元: `~/.codex/sessions/**/*.jsonl` から直近の assistant 出力を抽出
- agent_type は役割（researcher/engineer 等）。不明な場合は `executor=agent_source` として source を残す。
- completion は `🗣️` / `🎯 COMPLETED` パターン優先で抽出して frontmatter に入れる。
- Task `function_call_output` があれば **そちらを優先**して保存する。
- Task の `description` / `subagent_type` / `call_id` を frontmatter & metadata に追加する。
- transcript 書き込み遅延に備えて **短いリトライ**（デフォルト 2 回、200ms 間隔）を入れる。

## テスト TODO

- Cucumber の Then は 1 つの期待だけにする
  - 例: 「ならばメモリに agent_type が保存される」
  - completion は **別シナリオ**で検証する

## 参考

- UOCS の初心者向けまとめ: `docs/operations/uocs-overview.md`

## 未決

- `MEMORY/` の保存場所（repo 内/外）
- Hook 実装先（既存フック基盤に合わせるか、新規 CLI を追加するか）
- 対象範囲（Task のみ / すべての出力）

## TODO（未導入の依存）

- Observability ダッシュボード連携（イベント送信）: JSONL へ書き出しは実装、外部ダッシュボード送信は保留
- 通知（push/ローカル通知）: ローカル通知は実装、push/外部通知は保留

## 決定: Claude SubagentStop 互換

- Claude の hook からは `transcript_path` / `session_id` が渡る前提で対応する。
- Claude の transcript JSONL から `tool_use` → `tool_result` を対応づける。
- Claude の場合は `source=claude-hook` として記録し、event の `source_app` は `claude` を優先する。

## 実装メモ（進行中）

- 観測 UI（Rails）: `apps/web` で JSONL を読み込み表示する最小ビューを用意
  - `AGENTMEM_EVENTS_PATH` でイベントの JSONL パスを指定
