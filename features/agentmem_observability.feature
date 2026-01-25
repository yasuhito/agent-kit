# language: ja

機能: AgentMem observability
  AgentMem が観測イベントを JSONL に書き出せること

  背景:
    前提 Codex セッションに Task の結果がある:
      """
      {"timestamp":"2026-01-25T00:00:00Z","type":"session_meta","payload":{"id":"session-123","timestamp":"2026-01-25T00:00:00Z","cwd":"/home/yasuhito/Work/agent-kit","originator":"codex_cli_rs","model_provider":"openai","base_instructions":{"text":"You are Codex, based on GPT-5."}}}
      {"timestamp":"2026-01-25T00:00:01Z","type":"response_item","payload":{"type":"function_call","name":"Task","arguments":"{\"subagent_type\":\"researcher\",\"description\":\"Collect sources\",\"run_in_background\":true}","call_id":"call_task_1"}}
      {"timestamp":"2026-01-25T00:00:02Z","type":"response_item","payload":{"type":"function_call_output","call_id":"call_task_1","output":"🎯 COMPLETED: [AGENT:researcher] gathered sources"}}
      """
    もし AgentMem notify を実行する

  シナリオ: 観測イベント JSONL が作成される
    ならば 観測イベントが作成される

  シナリオ: 観測イベントに summary が入る
    ならば 観測イベントに summary "gathered sources" が入る

  シナリオ: 観測イベントに hook_event_type が入る
    ならば 観測イベントに hook_event_type "agent-turn-complete" が入る
