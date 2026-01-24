# tmux メモ

## 何に使う？

tmux は **セキュリティ境界** ではないが、`op` の実行場所を限定するための **運用ガードレール** として使う。

- `op`（1Password CLI）を **tmux 内のみ許可** することで、誤実行や自動実行を防ぐ。
- 1Password の承認プロンプトが出る場を「必ず人が見ているセッション」に限定できる。
- API キー取り扱いの場所を集約し、ログや別シェルに漏れる確率を下げる。
- スクリプトが自動で一時 tmux を作る場合もある（例: run_pipeline.sh）。

## 最小コマンド

```bash
# 新しいセッション作成
tmux new -s codex

# 既存セッションに入る
tmux attach -t codex

# セッション一覧
tmux ls
```

## よくある流れ

```bash
tmux new -s codex
cd /home/yasuhito/Work/agent-kit
skills/anthropic-best-practices-update/scripts/run_pipeline.sh
```

## スクリプトが作る一時セッションに入る

出力に `tmux attach -t <session>` が出たら、そのまま実行する。

## 注意

- tmux 自体が暗号的に安全なわけではない。**同一ユーザー権限内の運用ルール**として扱う。
- `op read` は 1Password デスクトップアプリが起動していないと失敗する。
