# md-converter スキル

## 決まったこと
- スキル名: md-converter
- 置き場所: skills/
- 用途: 正規化 Markdown をクリーンな Markdown に変換（MDX タグ変換）
- 利用スクリプト: skills/md-converter/scripts/anthropic_convert.rb（正本）
- 互換ラッパー: scripts/anthropic_convert.rb
- 入力: data/anthropic/state.json, data/anthropic/normalized/
- 出力: data/anthropic/generated/*.en.md
