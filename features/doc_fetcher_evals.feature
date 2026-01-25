# language: ja

機能: doc-fetcher evals（list のみ）
  doc-fetcher の list 実行が必要なプロンプトでは実行し、
  不要なプロンプトでは実行しないことを検証する。

  シナリオ: list-01 は list を実行する
    前提 doc-fetcher eval ケース "list-01" のプロンプト:
      """
      doc-fetcher で追跡中の URL 一覧を表示して
      """
    もし Codex でプロンプトを実行する
    ならば list コマンドが有効に実行されている

  シナリオ: list-02 は list を実行する
    前提 doc-fetcher eval ケース "list-02" のプロンプト:
      """
      state.json の sources を一覧で見せて
      """
    もし Codex でプロンプトを実行する
    ならば list コマンドが有効に実行されている

  シナリオ: list-03 は list を実行する
    前提 doc-fetcher eval ケース "list-03" のプロンプト:
      """
      doc-fetcher の登録済みソースを一覧表示して
      """
    もし Codex でプロンプトを実行する
    ならば list コマンドが有効に実行されている

  シナリオ: list-04 は list を実行する
    前提 doc-fetcher eval ケース "list-04" のプロンプト:
      """
      追跡している URL の一覧がほしい
      """
    もし Codex でプロンプトを実行する
    ならば list コマンドが有効に実行されている

  シナリオ: list-05 は list を実行する
    前提 doc-fetcher eval ケース "list-05" のプロンプト:
      """
      doc-fetcher のソース一覧を出して
      """
    もし Codex でプロンプトを実行する
    ならば list コマンドが有効に実行されている

  シナリオ: list-06 は list を実行する
    前提 doc-fetcher eval ケース "list-06" のプロンプト:
      """
      doc-fetcher の登録済み URL を教えて
      """
    もし Codex でプロンプトを実行する
    ならば list コマンドが有効に実行されている

  シナリオ: no-01 は list を実行しない
    前提 doc-fetcher eval ケース "no-01" のプロンプト:
      """
      README.md を要約して
      """
    もし Codex でプロンプトを実行する
    ならば list コマンドが実行されていない

  シナリオ: no-02 は list を実行しない
    前提 doc-fetcher eval ケース "no-02" のプロンプト:
      """
      data/doc-fetcher/state.json を開いて内容を教えて
      """
    もし Codex でプロンプトを実行する
    ならば list コマンドが実行されていない

  シナリオ: no-03 は list を実行しない
    前提 doc-fetcher eval ケース "no-03" のプロンプト:
      """
      best-practices の意味を一言で教えて
      """
    もし Codex でプロンプトを実行する
    ならば list コマンドが実行されていない

  シナリオ: no-04 は list を実行しない
    前提 doc-fetcher eval ケース "no-04" のプロンプト:
      """
      md-normalizer を使って文章を整形して
      """
    もし Codex でプロンプトを実行する
    ならば list コマンドが実行されていない

  シナリオ: no-05 は list を実行しない
    前提 doc-fetcher eval ケース "no-05" のプロンプト:
      """
      doc-fetcher を使って --url で取得して
      """
    もし Codex でプロンプトを実行する
    ならば list コマンドが実行されていない

  シナリオ: no-06 は list を実行しない
    前提 doc-fetcher eval ケース "no-06" のプロンプト:
      """
      doc_fetcher.rb --help を表示して
      """
    もし Codex でプロンプトを実行する
    ならば list コマンドが実行されていない
