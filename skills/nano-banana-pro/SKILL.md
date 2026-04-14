---
name: nano-banana-pro
description: Nano Banana Pro (Gemini 3 Pro Image) で画像生成/編集。画像作成・修正リクエストに使う。テキスト→画像、画像→画像に対応。1K/2K/4K、既存画像編集は `--input-image` を使う。
---

# Nano Banana Pro 画像生成 & 編集

Google の Nano Banana Pro API (Gemini 3 Pro Image) で新規画像生成または既存画像の編集を行う。

## 使い方

スクリプトは絶対パスで実行する（スキルディレクトリに `cd` しない）。

**新規画像生成:**
```bash
uv run ~/Work/agent-kit/skills/nano-banana-pro/scripts/generate_image.py --prompt "画像の説明" --filename "output-name.png" [--resolution 1K|2K|4K] [--api-key KEY]
```

**既存画像の編集:**
```bash
uv run ~/Work/agent-kit/skills/nano-banana-pro/scripts/generate_image.py --prompt "編集指示" --filename "output-name.png" --input-image "path/to/input.png" [--resolution 1K|2K|4K] [--api-key KEY]
```

**重要:** 必ずユーザーの作業ディレクトリから実行する。画像はスキルディレクトリではなく作業場所に保存する。

## デフォルトワークフロー（ドラフト → 反復 → 最終）

目標: プロンプトが固まるまで 4K を乱発せず、高速に反復する。

- ドラフト (1K): フィードバックを素早く回す
  - `uv run ~/Work/agent-kit/skills/nano-banana-pro/scripts/generate_image.py --prompt "<draft prompt>" --filename "yyyy-mm-dd-hh-mm-ss-draft.png" --resolution 1K`
- 反復: 小さな差分でプロンプトを調整し、毎回ファイル名を変える
  - 編集時は、納得するまで同じ `--input-image` を使い続ける
- 最終 (4K): プロンプトが固まってからだけ使う
  - `uv run ~/Work/agent-kit/skills/nano-banana-pro/scripts/generate_image.py --prompt "<final prompt>" --filename "yyyy-mm-dd-hh-mm-ss-final.png" --resolution 4K`

## 解像度オプション

Gemini 3 Pro Image API は 3 種類の解像度をサポートする（`K` は大文字）。

- **1K**（デフォルト）- 約 1024px
- **2K** - 約 2048px
- **4K** - 約 4096px

ユーザーの表現を API パラメータに寄せる目安:
- 解像度指定なし → `1K`
- 「低解像度」「1080」「1080p」「1K」→ `1K`
- 「2K」「2048」「普通」「中解像度」→ `2K`
- 「高解像度」「high-res」「hi-res」「4K」「ultra」→ `4K`

## API キー

スクリプトは次の順で API キーを確認する:
1. `--api-key`
2. `GEMINI_API_KEY`

1Password から読む場合:
```bash
export GEMINI_API_KEY=$(op read "op://Personal/Gemini API Key/credential")
```

どちらも無ければエラー終了。

## 事前確認 + よくある失敗

- 事前確認:
  - `command -v uv`
  - `test -n "$GEMINI_API_KEY"`（または `--api-key` を渡す）
  - 編集時: `test -f "path/to/input.png"`

- よくある失敗:
  - `Error: No API key provided.` → `GEMINI_API_KEY` を設定するか `--api-key` を渡す
  - `Error loading input image:` → パスが間違っている / 読めない。`--input-image` の実ファイルを確認
  - quota / permission / 403 系 → キーの権限不足、誤ったキー、または quota 超過

## ファイル名生成

ファイル名パターン: `yyyy-mm-dd-hh-mm-ss-name.png`

**形式:** `{timestamp}-{descriptive-name}.png`
- timestamp: 24 時間表記の現在日時
- name: 小文字 + ハイフン区切りの短い説明
- 説明部分は簡潔に（通常 1〜5 語）
- 会話やプロンプトの文脈を使う
- 不明ならランダム識別子でもよい（例: `x9k2`）

例:
- 「静かな日本庭園」→ `2025-11-23-14-23-05-japanese-garden.png`
- 「山に沈む夕日」→ `2025-11-23-15-30-12-sunset-mountains.png`
- 文脈が曖昧 → `2025-11-23-17-12-48-x9k2.png`

## 画像編集

既存画像を変更する場合:
1. ユーザーが画像パスを示しているか、カレントディレクトリで対象画像を特定できるか確認
2. `--input-image` にそのパスを渡す
3. `--prompt` には編集指示を入れる（例: 「空をもっとドラマチックに」「人物を削除」「水彩画風にする」）
4. 典型的な編集: 要素の追加/削除、スタイル変更、色調整、背景ぼかし など

## プロンプトの扱い

**新規生成:** ユーザーの画像説明は原則そのまま `--prompt` に渡す。明らかに情報不足なときだけ補う。

**既存画像の編集:** 編集指示を `--prompt` に渡す（例: `add a rainbow in the sky`, `make it look like a watercolor painting`）。

どちらもユーザーの創作意図を優先する。

## プロンプトテンプレート（当たり率高め）

ユーザーが曖昧なとき、または精密な編集が必要なときに使う。

- 生成用:
  - `Create an image of: <subject>. Style: <style>. Composition: <camera/shot>. Lighting: <lighting>. Background: <background>. Color palette: <palette>. Avoid: <list>.`

- 編集用（他は保持）:
  - `Change ONLY: <single change>. Keep identical: subject, composition/crop, pose, lighting, color palette, background, text, and overall style. Do not add new objects. If text exists, keep it unchanged.`

## 出力

- PNG をカレントディレクトリに保存する（`--filename` にディレクトリを含めればそこに保存）
- スクリプトは生成画像のフルパスを出力する
- **生成後に画像を読み返さない**。保存パスだけユーザーに伝える

## 例

**新規生成:**
```bash
uv run ~/Work/agent-kit/skills/nano-banana-pro/scripts/generate_image.py --prompt "A serene Japanese garden with cherry blossoms" --filename "2025-11-23-14-23-05-japanese-garden.png" --resolution 4K
```

**既存画像の編集:**
```bash
uv run ~/Work/agent-kit/skills/nano-banana-pro/scripts/generate_image.py --prompt "make the sky more dramatic with storm clouds" --filename "2025-11-23-14-25-30-dramatic-sky.png" --input-image "original-photo.jpg" --resolution 2K
```
