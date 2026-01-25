# doc-fetcher スキル

## 決まったこと
- スキル名: doc-fetcher
- 置き場所: skills/
- 用途: docs を決定論的に取得し、スナップショットと状態を保存
- 利用スクリプト: skills/doc-fetcher/scripts/doc_fetcher.rb（正本）
- 入力: `--url` で指定する URL（id は URL から自動生成）
- 出力: data/doc-fetcher/snapshots/, data/doc-fetcher/state.json
