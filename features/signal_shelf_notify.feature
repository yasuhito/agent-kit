# language: ja

機能: SignalShelf notify
  SignalShelf が Task の出力から agent_type と completion を抽出できること

  シナリオ: Task の tool_result を優先して記録する
    前提 Codex セッションに Task の結果がある
    もし SignalShelf notify を実行する
    ならば メモリに agent_type と completion が保存される
