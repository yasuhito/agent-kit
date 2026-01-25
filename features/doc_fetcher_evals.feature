# language: ja

機能: doc-fetcher evals（list のみ）
  doc-fetcher の list 実行が必要なプロンプトでは実行し、
  不要なプロンプトでは実行しないことを検証する。

  シナリオ: list: 追跡中 URL の一覧を表示する
    前提 doc-fetcher eval ケース "list-tracked-urls" のプロンプト:
      """
      doc-fetcher スキルで追跡中の URL 一覧を表示して。`skills/doc-fetcher/scripts/doc_fetcher.rb list` を使う想定。
      """
    もし Codex でプロンプトを実行する
    ならば list コマンドが有効に実行されている

  シナリオ: list: 登録済みソースを一覧表示する
    前提 doc-fetcher eval ケース "list-registered-sources" のプロンプト:
      """
      doc-fetcher スキルで登録済みソース一覧を出して。`skills/doc-fetcher/scripts/doc_fetcher.rb list` を使う想定。
      """
    もし Codex でプロンプトを実行する
    ならば list コマンドが有効に実行されている

  シナリオ: list: 登録済み URL を教える
    前提 doc-fetcher eval ケース "list-registered-urls" のプロンプト:
      """
      doc-fetcher スキルで登録済み URL を教えて。`skills/doc-fetcher/scripts/doc_fetcher.rb list` を使う想定。
      """
    もし Codex でプロンプトを実行する
    ならば list コマンドが有効に実行されている

  シナリオ: no: README の要約では list を実行しない
    前提 doc-fetcher eval ケース "no-readme-summary" のプロンプト:
      """
      README.md を要約して
      """
    もし Codex でプロンプトを実行する
    ならば list コマンドが実行されていない

  シナリオ: no: state.json の内容確認では list を実行しない
    前提 doc-fetcher eval ケース "no-state-json-cat" のプロンプト:
      """
      data/doc-fetcher/state.json を開いて内容を教えて
      """
    もし Codex でプロンプトを実行する
    ならば list コマンドが実行されていない

  シナリオ: no: 一般用語の質問では list を実行しない
    前提 doc-fetcher eval ケース "no-general-term" のプロンプト:
      """
      best-practices の意味を一言で教えて
      """
    もし Codex でプロンプトを実行する
    ならば list コマンドが実行されていない

  シナリオ: no: md-normalizer の依頼では list を実行しない
    前提 doc-fetcher eval ケース "no-md-normalizer" のプロンプト:
      """
      md-normalizer を使って文章を整形して
      """
    もし Codex でプロンプトを実行する
    ならば list コマンドが実行されていない

  シナリオ: no: fetch 指示だけでは list を実行しない
    前提 doc-fetcher eval ケース "no-fetch-only" のプロンプト:
      """
      doc-fetcher を使って --url で取得して
      """
    もし Codex でプロンプトを実行する
    ならば list コマンドが実行されていない

  シナリオ: no: ヘルプ表示では list を実行しない
    前提 doc-fetcher eval ケース "no-help" のプロンプト:
      """
      doc_fetcher.rb --help を表示して
      """
    もし Codex でプロンプトを実行する
    ならば list コマンドが実行されていない
