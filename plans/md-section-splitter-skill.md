# md-section-splitter スキル

## 決まったこと
- スキル名: md-section-splitter
- 置き場所: skills/
- 用途: 正規化済み Markdown を H2 セクション分割
- 利用スクリプト: skills/md-section-splitter/scripts/anthropic_split_sections.rb（正本）
- 互換ラッパー: scripts/anthropic_split_sections.rb
- 入力: data/anthropic/state.json, data/anthropic/normalized/
- 出力: data/anthropic/sections/, data/anthropic/state.json
