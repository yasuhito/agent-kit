# language: ja

機能: Rating Capture (UOCS 互換)
  ユーザーが評価を入力したときに observability-events.jsonl に記録される

  シナリオ: 数字だけの評価を検出する
    前提 Codex セッションに Task の結果がある:
      """
      {"timestamp":"2026-01-25T00:00:00Z","type":"session_meta","payload":{"id":"rating-session-1","timestamp":"2026-01-25T00:00:00Z","cwd":"/home/yasuhito/Work/agent-kit","originator":"codex_cli_rs","model_provider":"openai","base_instructions":{"text":"You are Codex."}}}
      {"timestamp":"2026-01-25T00:00:01Z","type":"response_item","payload":{"type":"message","role":"assistant","content":"Task completed."}}
      """
    かつ 入力メッセージがある:
      """
      7
      """
    もし AgentMem notify を実行する
    ならば 観測イベントに ExplicitRating で評価 7 が保存される

  シナリオ: コメント付き評価を検出する
    前提 Codex セッションに Task の結果がある:
      """
      {"timestamp":"2026-01-25T00:00:00Z","type":"session_meta","payload":{"id":"rating-session-2","timestamp":"2026-01-25T00:00:00Z","cwd":"/home/yasuhito/Work/agent-kit","originator":"codex_cli_rs","model_provider":"openai","base_instructions":{"text":"You are Codex."}}}
      {"timestamp":"2026-01-25T00:00:01Z","type":"response_item","payload":{"type":"message","role":"assistant","content":"Task completed."}}
      """
    かつ 入力メッセージがある:
      """
      8 - good job
      """
    もし AgentMem notify を実行する
    ならば 観測イベントに ExplicitRating で評価 8 が保存される
    かつ 観測イベントにコメント "good job" が保存される

  シナリオ: 誤検出を防止する - 7 items
    前提 Codex セッションに Task の結果がある:
      """
      {"timestamp":"2026-01-25T00:00:00Z","type":"session_meta","payload":{"id":"rating-session-3","timestamp":"2026-01-25T00:00:00Z","cwd":"/home/yasuhito/Work/agent-kit","originator":"codex_cli_rs","model_provider":"openai","base_instructions":{"text":"You are Codex."}}}
      {"timestamp":"2026-01-25T00:00:01Z","type":"response_item","payload":{"type":"message","role":"assistant","content":"Task completed."}}
      """
    かつ 入力メッセージがある:
      """
      7 items to fix
      """
    もし AgentMem notify を実行する
    ならば 観測イベントに ExplicitRating が含まれない

  シナリオ: 低評価時に UOCS キャプチャファイルを保存する
    前提 Codex セッションに Task の結果がある:
      """
      {"timestamp":"2026-01-25T00:00:00Z","type":"session_meta","payload":{"id":"rating-session-4","timestamp":"2026-01-25T00:00:00Z","cwd":"/home/yasuhito/Work/agent-kit","originator":"codex_cli_rs","model_provider":"openai","base_instructions":{"text":"You are Codex."}}}
      {"timestamp":"2026-01-25T00:00:01Z","type":"response_item","payload":{"type":"message","role":"assistant","content":"Task completed."}}
      """
    かつ 入力メッセージがある:
      """
      4 - needs improvement
      """
    もし AgentMem notify を実行する
    ならば 観測イベントに ExplicitRating で評価 4 が保存される
    かつ UOCS カテゴリにキャプチャファイルが作成される

  シナリオ: Claude Code の prompt フィールドから評価を検出する
    前提 Claude セッションがある
    かつ prompt フィールドに "9 - excellent" がある
    もし AgentMem notify を実行する
    ならば 観測イベントに ExplicitRating で評価 9 が保存される
