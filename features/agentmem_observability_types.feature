# language: ja

機能: AgentMem observability (event types)
  AgentMem が複数のイベント種別を書き出せること

  背景:
    前提 Codex セッションに Task の結果がある:
      """
      {"timestamp":"2026-01-25T00:00:00Z","type":"session_meta","payload":{"id":"session-789","timestamp":"2026-01-25T00:00:00Z","cwd":"/home/yasuhito/Work/agent-kit","originator":"codex_cli_rs","model_provider":"openai","base_instructions":{"text":"You are Codex, based on GPT-5."}}}
      {"timestamp":"2026-01-25T00:00:01Z","type":"response_item","payload":{"type":"function_call","name":"Task","arguments":"{\"subagent_type\":\"researcher\",\"description\":\"Collect sources\",\"run_in_background\":true}","call_id":"call_task_3"}}
      {"timestamp":"2026-01-25T00:00:02Z","type":"response_item","payload":{"type":"function_call_output","call_id":"call_task_3","output":"🎯 COMPLETED: [AGENT:researcher] gathered sources"}}
      """
    前提 入力メッセージがある:
      """
      Find relevant sources.
      """
    もし AgentMem notify を実行する

  シナリオ: UserPromptSubmit が書き出される
    ならば 観測イベントに hook_event_type "UserPromptSubmit" が含まれる

  シナリオ: PostToolUse が書き出される
    ならば 観測イベントに hook_event_type "PostToolUse" が含まれる
