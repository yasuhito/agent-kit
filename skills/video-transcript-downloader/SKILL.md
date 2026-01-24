---
name: video-transcript-downloader
description: YouTube およびその他の yt-dlp 対応サイトから動画、音声、字幕、綺麗な段落形式の文字起こしをダウンロード。「この動画をダウンロードして」「このクリップを保存して」「音声を抽出して」「字幕を取得して」「文字起こしを取得して」などのリクエスト、または yt-dlp/ffmpeg やフォーマット/プレイリストのトラブルシューティング時に使用。
---

# Video Transcript Downloader

`./scripts/vtd.js` でできること:
- 文字起こしを綺麗な段落で出力（タイムスタンプはオプション）
- 動画/音声/字幕をダウンロード

文字起こしの動作:
- YouTube: 可能なら `youtube-transcript-plus` 経由で取得
- その他: `yt-dlp` で字幕を取得し、段落形式にクリーンアップ

## セットアップ

```bash
cd ~/Work/agent-kit/skills/video-transcript-downloader && npm ci
```

## 文字起こし（デフォルト: 綺麗な段落）

```bash
./scripts/vtd.js transcript --url 'https://…'
./scripts/vtd.js transcript --url 'https://…' --lang ja
./scripts/vtd.js transcript --url 'https://…' --timestamps
./scripts/vtd.js transcript --url 'https://…' --keep-brackets
```

## 動画 / 音声 / 字幕のダウンロード

```bash
./scripts/vtd.js download --url 'https://…' --output-dir ~/Downloads
./scripts/vtd.js audio --url 'https://…' --output-dir ~/Downloads
./scripts/vtd.js subs --url 'https://…' --output-dir ~/Downloads --lang ja
```

## フォーマット（一覧 + 選択）

利用可能なフォーマットを一覧表示（フォーマット ID、解像度、コンテナ、音声のみ、など）:

```bash
./scripts/vtd.js formats --url 'https://…'
```

特定のフォーマット ID をダウンロード（例）:

```bash
./scripts/vtd.js download --url 'https://…' --output-dir ~/Downloads -- --format 137+140
```

再エンコードなしで MP4 コンテナを優先（可能なら remux）:

```bash
./scripts/vtd.js download --url 'https://…' --output-dir ~/Downloads -- --remux-video mp4
```

## メモ

- デフォルトの文字起こし出力は単一の段落。`--timestamps` は要求された時のみ使用
- `[Music]` のような括弧付きキューはデフォルトで削除。`--keep-brackets` で保持
- `transcript` フォールバック、`download`、`audio`、`subs`、`formats` では `--` の後に追加の `yt-dlp` 引数を渡せる

```bash
./scripts/vtd.js formats --url 'https://…' -- -v
```

## トラブルシューティング（必要な時のみ）

- `yt-dlp` / `ffmpeg` がない場合:

```bash
# Linux
sudo pacman -S yt-dlp ffmpeg  # Arch
sudo apt install yt-dlp ffmpeg  # Debian/Ubuntu

# macOS
brew install yt-dlp ffmpeg
```

- 確認:

```bash
yt-dlp --version
ffmpeg -version | head -n 1
```
