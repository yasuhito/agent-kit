# systemd timer で Best Practices を定期更新

Arch Linux など systemd が標準の環境では、cron よりも **systemd user timer** が扱いやすい。
ログの追跡や失敗時の調査が簡単で、運用向き。

## 概要

- 更新対象: `skills/anthropic-best-practices-update/scripts/run_pipeline.sh`（デフォルトソースを更新）
- 翻訳: `OPENAI_API_KEY` を環境ファイルで渡す（tmux/op なしで動作）
- 実行: `systemd --user` の timer で週次実行

## 1) 環境ファイルを用意

```bash
mkdir -p ~/.config/agent-kit
chmod 700 ~/.config/agent-kit

cat <<'ENV' > ~/.config/agent-kit/env
OPENAI_API_KEY=sk-...
ENV

chmod 600 ~/.config/agent-kit/env
```

## 2) service ユニット

`~/.config/systemd/user/anthropic-bp.service`

```ini
[Unit]
Description=Anthropic best-practices updater

[Service]
Type=oneshot
WorkingDirectory=/home/yasuhito/Work/agent-kit
EnvironmentFile=%h/.config/agent-kit/env
ExecStart=/usr/bin/env bundle exec skills/anthropic-best-practices-update/scripts/run_pipeline.sh
```

## 3) timer ユニット

`~/.config/systemd/user/anthropic-bp.timer`

```ini
[Unit]
Description=Run Anthropic best-practices updater weekly

[Timer]
OnCalendar=weekly
Persistent=true
RandomizedDelaySec=1h

[Install]
WantedBy=timers.target
```

## 4) 有効化

```bash
systemctl --user daemon-reload
systemctl --user enable --now anthropic-bp.timer
systemctl --user list-timers | rg anthropic-bp
```

ログ確認:

```bash
journalctl --user -u anthropic-bp.service -f
```

## 5) ログイン中以外でも動かす場合

ユーザーがログインしていないと timer が動かない環境では、linger を有効化する:

```bash
loginctl enable-linger "$USER"
```

## 注意点

- `bundle exec` を使うことで openssl gem (>= 3.3.2) を確実に使用できる。
- `OPENAI_API_KEY` は環境ファイルで管理し、リポジトリには入れない。
- まずは `--skip-translate` で試し、ログが安定してから翻訳を有効化するのも手。
