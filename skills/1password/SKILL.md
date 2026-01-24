---
name: 1password
description: 1Password CLI (op) のセットアップと使用。CLI のインストール、デスクトップアプリ連携、サインイン（シングル/マルチアカウント）、シークレットの読み取り/注入/実行に使用。
homepage: https://developer.1password.com/docs/cli/get-started/
metadata: {"clawdbot":{"emoji":"🔐","requires":{"bins":["op"]},"install":[{"id":"brew","kind":"brew","formula":"1password-cli","bins":["op"],"label":"1Password CLI インストール (brew)"}]}}
---

# 1Password CLI

公式 CLI のスタートガイドに従う。インストールコマンドを推測しない。

## リファレンス

- `references/get-started.md`（インストール + アプリ連携 + サインインフロー）
- `references/cli-examples.md`（実際の `op` 使用例）

## ワークフロー

1. OS + シェルを確認
2. CLI の存在確認: `op --version`
3. デスクトップアプリ連携が有効でアプリがアンロックされていることを確認
4. **必須**: すべての `op` コマンド用に新しい tmux セッションを作成（tmux 外で直接 `op` を呼ばない）
5. tmux 内でサインイン/認可: `op signin`（アプリのプロンプトが表示される）
6. tmux 内でアクセス確認: `op whoami`（シークレット読み取り前に成功する必要がある）
7. 複数アカウントの場合: `--account` または `OP_ACCOUNT` を使用

## 必須 tmux セッション

シェルツールはコマンドごとに新しい TTY を使用。再プロンプトや失敗を避けるため、常に専用の tmux セッション内で `op` を実行。

例（`tmux` スキルのソケット規約参照、古いセッション名を再利用しない）:

```bash
SOCKET_DIR="${CLAWDBOT_TMUX_SOCKET_DIR:-${TMPDIR:-/tmp}/clawdbot-tmux-sockets}"
mkdir -p "$SOCKET_DIR"
SOCKET="$SOCKET_DIR/clawdbot-op.sock"
SESSION="op-auth-$(date +%Y%m%d-%H%M%S)"

tmux -S "$SOCKET" new -d -s "$SESSION" -n shell
tmux -S "$SOCKET" send-keys -t "$SESSION":0.0 -- "op signin --account my.1password.com" Enter
tmux -S "$SOCKET" send-keys -t "$SESSION":0.0 -- "op whoami" Enter
tmux -S "$SOCKET" send-keys -t "$SESSION":0.0 -- "op vault list" Enter
tmux -S "$SOCKET" capture-pane -p -J -t "$SESSION":0.0 -S -200
tmux -S "$SOCKET" kill-session -t "$SESSION"
```

## ガードレール

- シークレットをログ、チャット、コードにペーストしない
- ディスクへの書き込みより `op run` / `op inject` を優先
- アプリ連携なしでサインインが必要な場合は `op account add` を使用
- "account is not signed in" が返ったら、tmux 内で `op signin` を再実行しアプリで認可
- tmux 外で `op` を実行しない。tmux が使えない場合は止まって確認
