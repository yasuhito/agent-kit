# Codex notify と AgentMem

Codex の `notify` を使って、エージェントのターン完了ごとに AgentMem を記録する。

## 目的

- `agent-turn-complete` をトリガにして、出力を `~/.agent-kit/MEMORY` に保存する。
- 失敗しても Codex の本流を止めない（exit 0 前提）。

## 設定手順

1) `scripts/agentmem_notify.rb` を実行可能にする  
2) Codex の設定ファイルに `notify` を追加する  

例（`notify` の指定）:

```toml
notify = ["ruby", "/home/yasuhito/Work/agent-kit/scripts/agentmem_notify.rb"]
```

## 環境変数

- `AGENTMEM_ROOT`: 保存先ルート（既定 `~/.agent-kit/MEMORY`）
- `AGENTMEM_DEBUG`: 1 をセットするとエラーを stderr に出す
- `CODEX_SESSIONS_DIR`: Codex のセッション JSONL ルート（既定 `~/.codex/sessions`）
- `AGENTMEM_RETRY_ATTEMPTS`: transcript 探索の短リトライ回数（既定 2）
- `AGENTMEM_RETRY_DELAY_MS`: リトライ間隔（ms、既定 200）
- `AGENTMEM_NOTIFY_COMMAND`: 通知コマンド（例: `notify-send` や任意スクリプト）

## 出力

`~/.agent-kit/MEMORY/<CATEGORY>/<YYYY-MM>/` に Markdown を保存する。
併せて `~/.agent-kit/MEMORY/STATE/observability-events.jsonl` にイベントを追記する。
`UserPromptSubmit` / `PreToolUse` / `PostToolUse` / `Stop` / `agent-turn-complete` を出力する。

## 取得元

- `notify` の JSON だけでなく、`~/.codex/sessions` の JSONL を参照して
  直近の assistant 出力を拾う（UOCS の transcript 取得に寄せた実装）。
- `Task` の `function_call_output` がある場合は **そちらを優先**して保存する。
  併せて `task_description` / `task_subagent_type` / `task_call_id` などを frontmatter に記録する。

## agent_type の扱い

- UOCS では **agent_type = 役割**（researcher/engineer など）。
- Codex では役割情報が無い場合があるため、`executor` は **source（codex/claude）** を fallback にする。
- そのため frontmatter に `agent_type` と `agent_source` を追加して区別する。

## completion 抽出

- `🗣️ AgentName: ...` と `🎯 COMPLETED: [AGENT:type] ...` を優先して抽出
- 取れた場合は `agent_completion` に保存
