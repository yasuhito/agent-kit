---
summary: 'マルチエージェントシステムのルールと連携方法'
read_when:
  - サブエージェントの連携や tmux ベースのエージェントセッション実行時
---

# Claude サブエージェント クイックスタート

## CLI 基本

- 長時間実行するサブエージェントは tmux 内で起動（セッションを永続化）:

  ```bash
  tmux new-session -d -s claude-haiku 'claude --model haiku'
  tmux attach -t claude-haiku
  ```

  セッション内で `/model` を実行してアクティブなモデルを確認。必要に応じて切り替え。

- アタッチせずに指示を送る場合: `bun scripts/agent-send.ts --session <name> -- "コマンド"` で実行中のエージェントセッションにテキストを送信。

- ターンアラウンドを速くするため、最初に高速な Haiku モデルに切り替える（`claude --model haiku --dangerously-skip-permissions …` または セッション内で `/model haiku`）。

- 2つのモード:
  - **ワンショットタスク**（単一の要約、短い回答）: tmux セッションで `claude --model haiku --dangerously-skip-permissions --print …` を実行、`sleep 30` で待機、出力バッファを読む。
  - **インタラクティブタスク**（複数ファイル編集、反復的なプロンプト）: tmux で `claude --model haiku --dangerously-skip-permissions` を起動、`tmux send-keys` でプロンプト送信、`tmux capture-pane` で完了した応答をキャプチャ。Haiku が終了するまで各ターン間で sleep が必要。

## ワンショットプロンプト

- CLI はワンショットモードで末尾引数としてプロンプトを受け取る。複数行プロンプトはパイプで: `echo "..." | claude --print`
- 後処理用に構造化フィールド（例: 要約 + 箇条書き）が必要なら `--output-format json` を追加。
- ファイル全体を読むことを明示: 「docs/example.md を全て読んで、全セクションをカバーする 2〜3 文の要約を作成して」

## 一括 Markdown 変換

- まず markdown インベントリを作成（`pnpm run docs:list`）、ファイル名のバッチを Claude セッションに送る。
- 各バッチで単一の指示を出す: 「これらのファイルを YAML フロントマター付きで書き換え、他のコンテンツはそのまま維持」。明示的なリストを渡せば Haiku は複数ファイル編集をループできる。
- Claude が成功を報告したら、次のバッチに移る前にローカルで各ファイルを diff（`git diff docs/<file>.md`）。

## Ralph 連携メモ

- Ralph（`scripts/ralph.ts` 参照）は tmux セッションを起動、ワーカーを自動起動、`claude --dangerously-skip-permissions` でスーパーバイザーとして Claude を呼び出す。
- スーパーバイザーの応答は `CONTINUE`、`SEND: <メッセージ>`、または `RESTART` で終わる必要がある。Ralph はこれらのトークンをパースして次のアクションを決定。
- Ralph を手動起動: `bun scripts/ralph.ts start --goal "…" [--markdown path]`。進捗はデフォルトで `.ralph/progress.md` に記録。
- ワーカーセッションにアドホックな指示を送る: `bun scripts/ralph.ts send-to-worker -- "ガイダンス"`
