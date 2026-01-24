---
summary: 'タスク開始時の Codex ピックアップチェックリスト'
read_when:
  - /pickup プロンプトを作成または新しいタスクをオンボードする時
---
# /pickup

目的: 作業開始時に素早くコンテキストを再構築。

ステップ:
1) AGENTS.MD ポインター + 関連ドキュメントを読む（存在すれば `pnpm run docs:list` を実行）
2) リポジトリ状態: `git status -sb`、ローカルコミットの確認、現在のブランチ/PR を確認
3) CI/PR: `gh pr view <num> --comments --files`（またはブランチから PR を特定）、失敗しているチェックを記録
4) tmux/プロセス: セッションをリストし、必要ならアタッチ:
   - `tmux list-sessions`
   - セッションが存在する場合: `tmux attach -t codex-shell` または `tmux capture-pane -p -J -t codex-shell:0.0 -S -200`
5) テスト/チェック: 最後に実行されたもの（ハンドオフノート/CI から）と最初に実行するものを記録
6) 次の 2-3 アクションを箇条書きで計画し実行

出力形式: 簡潔な箇条書きサマリー。ライブセッションがある場合はコピペ可能な tmux attach/capture コマンドを含める。

配置場所: グローバルプロンプトは `~/.codex/prompts/pickup.md`。このファイルは編集用のミラー。
