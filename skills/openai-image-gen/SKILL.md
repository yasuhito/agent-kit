---
name: openai-image-gen
description: OpenAI Images API で画像をバッチ生成。ランダムプロンプトサンプラー + `index.html` ギャラリー。
---

# OpenAI 画像生成

「ランダムだが構造化された」プロンプトを生成し、OpenAI Images API でレンダリング。

## セットアップ

- 環境変数 `OPENAI_API_KEY` が必要
- 1Password から取得する場合：
  ```bash
  export OPENAI_API_KEY=$(op read "op://Personal/OpenAI API Key/credential")
  ```

## 実行

任意のディレクトリから（出力は `~/Work/tmp/...` または `./tmp/...`）：

```bash
# 1Password からキーを取得して実行
OPENAI_API_KEY=$(op read "op://Personal/OpenAI API Key/credential") \
  python3 ~/Work/agent-kit/skills/openai-image-gen/scripts/gen.py

# ギャラリーを開く
xdg-open ~/Work/tmp/openai-image-gen-*/index.html
```

便利なフラグ：

```bash
# 16枚生成
python3 ~/Work/agent-kit/skills/openai-image-gen/scripts/gen.py --count 16 --model gpt-image-1.5

# 特定のプロンプトで4枚生成
python3 ~/Work/agent-kit/skills/openai-image-gen/scripts/gen.py --prompt "ultra-detailed studio photo of a lobster astronaut" --count 4

# サイズと品質を指定
python3 ~/Work/agent-kit/skills/openai-image-gen/scripts/gen.py --size 1536x1024 --quality high --out-dir ./out/images
```

## 出力

- `*.png` 画像ファイル
- `prompts.json`（プロンプト ↔ ファイル マッピング）
- `index.html`（サムネイルギャラリー）
