---
summary: 'tmux + 1Password CLI (op) で npm publish する方法'
read_when:
  - シークレットをコピペせずに npm publish したい時
  - 1Password から npm OTP/TOTP を取得したい時
---

# npm publish via tmux + op

目的: トークンやパスワードをターミナルログに残さずに npm publish する。

## 前提条件

- 1Password デスクトップアプリがアンロック済み + CLI 連携が有効
- `op` インストール済み
- `tmux` インストール済み

## tmux セッション（必須）

`op` 認証がコマンド間で維持されるよう、永続的な tmux セッションを使用。

```bash
SOCKET_DIR="${CLAWDBOT_TMUX_SOCKET_DIR:-${TMPDIR:-/tmp}/clawdbot-tmux-sockets}"
mkdir -p "$SOCKET_DIR"
SOCKET="$SOCKET_DIR/op-auth.sock"
SESSION="op-auth-$(date +%Y%m%d-%H%M%S)"

tmux -S "$SOCKET" new -d -s "$SESSION" -n shell
tmux -S "$SOCKET" send-keys -t "$SESSION":1.1 -- "op signin" Enter
tmux -S "$SOCKET" send-keys -t "$SESSION":1.1 -- "op whoami" Enter
```

## 推奨: 粒度の細かい自動化トークン（+ オプションで OTP）

1Password に粒度の細かい npm トークン（フィールド名 `token`）を保存、必要なら TOTP も。

```bash
TOKEN_REF='op://<Vault>/<Item>/token'
OTP_REF='op://<Vault>/<Item>/one-time password?attribute=otp'

tmux -S "$SOCKET" send-keys -t "$SESSION":1.1 -- "NODE_AUTH_TOKEN=\"\$(op read \"$TOKEN_REF\" | tr -d \"\\n\")\" npm publish --otp \"\$(op read \"$OTP_REF\" | tr -d \"\\n\")\"" Enter
```

注意:
- `tr -d "\n"` でペースト/読み取り時の余計な改行を防ぐ
- トークン/OTP を表示しない（`echo` なし、`set -x` なし、OTP 直後のペインキャプチャなし）

## すでにログイン済みの場合: OTP のみで publish

`npm whoami` が動作するなら、publish には OTP だけが必要:

```bash
OTP_REF='op://<Vault>/<Item>/one-time password?attribute=otp'
tmux -S "$SOCKET" send-keys -t "$SESSION":1.1 -- "npm publish --otp \"\$(op read \"$OTP_REF\" | tr -d \"\\n\")\"" Enter
```

ヒント: CI トークンが設定されていないか確認:

```bash
env -u NPM_TOKEN -u NODE_AUTH_TOKEN npm whoami
```

## フォールバック: op バッファを使った `npm login`（エコーなし）

パスワード認証が避けられない場合、tmux バッファにパイプしてペーストすることでシークレットの入力を回避。

```bash
USER_REF='op://<Vault>/<Item>/name'
PASS_REF='op://<Vault>/<Item>/password'
EMAIL_REF='op://<Vault>/<Item>/email'
OTP_REF='op://<Vault>/<Item>/one-time password?attribute=otp'

# バッファをロード（末尾の改行を削除）
tmux -S "$SOCKET" send-keys -t "$SESSION":1.1 -- "op read \"$USER_REF\"  | tr -d \"\\n\" | tmux -S \"$SOCKET\" load-buffer -b npm_user  -" Enter
tmux -S "$SOCKET" send-keys -t "$SESSION":1.1 -- "op read \"$PASS_REF\"  | tr -d \"\\n\" | tmux -S \"$SOCKET\" load-buffer -b npm_pass  -" Enter
tmux -S "$SOCKET" send-keys -t "$SESSION":1.1 -- "op read \"$EMAIL_REF\" | tr -d \"\\n\" | tmux -S \"$SOCKET\" load-buffer -b npm_email -" Enter

# login を実行、プロンプトでペースト（Email/OTP も同様のパターン）
tmux -S "$SOCKET" send-keys -t "$SESSION":1.1 -- "npm login --auth-type=legacy" Enter
tmux -S "$SOCKET" paste-buffer -t "$SESSION":1.1 -b npm_user
tmux -S "$SOCKET" send-keys    -t "$SESSION":1.1 -- Enter
tmux -S "$SOCKET" paste-buffer -t "$SESSION":1.1 -b npm_pass
tmux -S "$SOCKET" send-keys    -t "$SESSION":1.1 -- Enter
```

注意点:
- npm が "Incorrect or missing password" と言う場合、1Password のパスワードが古いかペーストがプロンプトに届いていない
- OTP ペースト後に `tmux capture-pane` を実行しない（エコーされる可能性）。デバッグが必要なら 30〜60 秒待つ
- パスワードフィールドの繰り返し読み取りは 1Password の「パスワード使用/コピー」アラートを複数回トリガーする可能性がある。OTP のみのフローで回避

## 確認

```bash
npm whoami
npm view <pkg> version
```

## クリーンアップ

```bash
tmux -S "$SOCKET" kill-session -t "$SESSION"
rm -f "$SOCKET"
```
