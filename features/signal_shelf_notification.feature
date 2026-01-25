# language: ja

機能: SignalShelf notifications
  バックグラウンドタスク完了時に通知できること

  背景:
    前提 Codex セッションに Task の結果がある:
      """
      {"timestamp":"2026-01-25T00:00:00Z","type":"session_meta","payload":{"id":"session-123","timestamp":"2026-01-25T00:00:00Z","cwd":"/home/yasuhito/Work/agent-kit","originator":"codex_cli_rs","model_provider":"openai","base_instructions":{"text":"You are Codex, based on GPT-5."}}}
      {"timestamp":"2026-01-25T00:00:01Z","type":"response_item","payload":{"type":"function_call","name":"Task","arguments":"{\"subagent_type\":\"researcher\",\"description\":\"Collect sources\",\"run_in_background\":true}","call_id":"call_task_1"}}
      {"timestamp":"2026-01-25T00:00:02Z","type":"response_item","payload":{"type":"function_call_output","call_id":"call_task_1","output":"🎯 COMPLETED: [AGENT:researcher] gathered sources"}}
      """
    前提 通知コマンドが設定されている
    もし SignalShelf notify を実行する

  シナリオ: バックグラウンド完了で通知が送信される
    ならば 通知が送信される
