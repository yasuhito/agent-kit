# language: ja

機能: AgentMem notify（短いリトライ）
  transcript が遅れて生成されても短いリトライで取得できること

  シナリオ: transcript が遅れて書き込まれる場合でも completion を記録する
    前提 Codex セッションに Task の結果が遅れて書き込まれる:
      """
      {"timestamp":"2026-01-25T00:00:00Z","type":"session_meta","payload":{"id":"session-456","timestamp":"2026-01-25T00:00:00Z","cwd":"/home/yasuhito/Work/agent-kit","originator":"codex_cli_rs","model_provider":"openai","base_instructions":{"text":"You are Codex, based on GPT-5."}}}
      {"timestamp":"2026-01-25T00:00:01Z","type":"response_item","payload":{"type":"function_call","name":"Task","arguments":"{\"subagent_type\":\"researcher\",\"description\":\"Collect sources\",\"run_in_background\":true}","call_id":"call_task_2"}}
      {"timestamp":"2026-01-25T00:00:02Z","type":"response_item","payload":{"type":"function_call_output","call_id":"call_task_2","output":"🎯 COMPLETED: [AGENT:researcher] delayed capture"}}
      """
    もし AgentMem notify を実行する
    ならば メモリに completion "delayed capture" が保存される
