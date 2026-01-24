# doc-fetcher スキル

## 決まったこと
- スキル名: doc-fetcher
- 置き場所: skills/
- 用途: docs を決定論的に取得し、スナップショットと状態を保存
- 利用スクリプト: skills/doc-fetcher/scripts/anthropic_fetch.rb（正本）
- 互換ラッパー: scripts/anthropic_fetch.rb
- 入力: data/anthropic/sources.yaml
- 出力: data/anthropic/snapshots/, data/anthropic/state.json
