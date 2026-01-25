# language: ja

機能: SignalShelf notify
  SignalShelf が Task の出力から frontmatter の主要項目を抽出できること

  背景:
    前提 Codex セッションに Task の結果がある:
      """
      {"timestamp":"2026-01-25T00:00:00Z","type":"session_meta","payload":{"id":"session-123","timestamp":"2026-01-25T00:00:00Z","cwd":"/home/yasuhito/Work/agent-kit","originator":"codex_cli_rs","model_provider":"openai","base_instructions":{"text":"You are Codex, based on GPT-5."}}}
      {"timestamp":"2026-01-25T00:00:01Z","type":"response_item","payload":{"type":"function_call","name":"Task","arguments":"{\"subagent_type\":\"researcher\",\"description\":\"Collect sources\",\"run_in_background\":true}","call_id":"call_task_1"}}
      {"timestamp":"2026-01-25T00:00:02Z","type":"response_item","payload":{"type":"function_call_output","call_id":"call_task_1","output":"🎯 COMPLETED: [AGENT:researcher] gathered sources"}}
      """
    もし SignalShelf notify を実行する

  シナリオ: Task の tool_result から agent_type を記録する
    ならば メモリに agent_type が保存される

  シナリオ: Task の tool_result から executor を記録する
    ならば メモリに executor が保存される

  シナリオ: Task の tool_result から task_description を記録する
    ならば メモリに task_description が保存される

  シナリオ: Task の tool_result から task_subagent_type を記録する
    ならば メモリに task_subagent_type が保存される

  シナリオ: Task の tool_result から task_run_in_background を記録する
    ならば メモリに task_run_in_background が保存される

  シナリオ: Task の tool_result から task_call_id を記録する
    ならば メモリに task_call_id が保存される

  シナリオ: Task の tool_result から completion を記録する
    ならば メモリに completion が保存される
