# anthropic-best-practices-update スキル

## 決まったこと
- スキル名: anthropic-best-practices-update
- 置き場所: skills/
- 用途: Best Practices 更新パイプラインの一括実行
- ランナー: skills/anthropic-best-practices-update/scripts/run_pipeline.sh
- オプション: --id（特定ソース）, --skip-translate, --insecure
- 翻訳: GPT-5 + 1Password + tmux（tmux 外は一時セッションで実行、--skip-translate で回避）
