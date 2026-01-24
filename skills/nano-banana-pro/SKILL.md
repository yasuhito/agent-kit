---
name: nano-banana-pro
description: Nano Banana Pro (Gemini 3 Pro Image) で画像生成/編集。画像作成・修正リクエストに使用。テキスト→画像、画像→画像対応。1K/2K/4K 解像度。
---

# Nano Banana Pro 画像生成 & 編集

Google の Nano Banana Pro API (Gemini 3 Pro Image) で新規画像生成または既存画像の編集。

## 使い方

絶対パスでスクリプト実行（スキルディレクトリに cd しない）:

**新規画像生成:**
```bash
uv run ~/Work/agent-kit/skills/nano-banana-pro/scripts/generate_image.py --prompt "画像の説明" --filename "output-name.png" [--resolution 1K|2K|4K] [--api-key KEY]
```

**既存画像の編集:**
```bash
uv run ~/Work/agent-kit/skills/nano-banana-pro/scripts/generate_image.py --prompt "編集指示" --filename "output-name.png" --input-image "path/to/input.png" [--resolution 1K|2K|4K] [--api-key KEY]
```

**重要:** ユーザーの作業ディレクトリから実行すること。画像はスキルディレクトリではなく作業場所に保存される。

## デフォルトワークフロー (ドラフト → 反復 → 最終)

目標: プロンプトが確定するまで 4K で時間を無駄にしない高速反復。

- ドラフト (1K): 高速フィードバックループ
- 反復: プロンプトを小さく調整。実行ごとにファイル名を変える
  - 編集時: 満足するまで同じ `--input-image` を使い続ける
- 最終 (4K): プロンプト確定後のみ

## 解像度オプション

- **1K** (デフォルト) - ~1024px
- **2K** - ~2048px
- **4K** - ~4096px

## API キー

スクリプトはこの順序で API キーを確認:
1. `--api-key` 引数
2. `GEMINI_API_KEY` 環境変数

1Password から取得する場合：
```bash
export GEMINI_API_KEY=$(op read "op://Personal/Gemini API Key/credential")
```

どちらもなければエラー終了。

## ファイル名生成

パターン: `yyyy-mm-dd-hh-mm-ss-name.png`

例:
- "静かな日本庭園" → `2025-11-23-14-23-05-japanese-garden.png`
- "山に沈む夕日" → `2025-11-23-15-30-12-sunset-mountains.png`

## 画像編集

既存画像を修正する場合:
1. 画像パスを確認
2. `--input-image` パラメータにパスを指定
3. プロンプトに編集指示を含める（例: "空をもっとドラマチックに", "人物を削除", "カートゥーンスタイルに変更"）

## プロンプトテンプレート

**生成用:**
"Create an image of: <subject>. Style: <style>. Composition: <camera/shot>. Lighting: <lighting>. Background: <background>. Color palette: <palette>. Avoid: <list>."

**編集用（他は保持）:**
"Change ONLY: <single change>. Keep identical: subject, composition/crop, pose, lighting, color palette, background, text, and overall style."

## 出力

- PNG をカレントディレクトリに保存
- 生成された画像のフルパスを出力
- **画像を読み返さない** - 保存パスをユーザーに伝えるだけ
