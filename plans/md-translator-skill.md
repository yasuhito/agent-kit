# md-translator スキル

## 決まったこと
- スキル名: md-translator
- 置き場所: skills/
- 用途: Markdown を日本語に翻訳
- 利用スクリプト: skills/md-translator/scripts/openai_translate_markdown.rb（正本）
- 互換ラッパー: scripts/openai_translate_markdown.rb
- 翻訳モデル: OpenAI GPT-5
- API キー取得: 1Password の op + tmux 必須
- 1Password デスクトップアプリが起動していないと `op read` が失敗する
- SSL 証明書エラー回避: --insecure を使用
- OpenSSL CRL エラー対策: openssl gem を 3.3.2 以上に更新
- 翻訳のタイムアウト調整: --open-timeout / --read-timeout を利用
- まずは日本語固定
