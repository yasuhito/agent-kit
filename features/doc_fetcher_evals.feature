# language: ja

機能: doc-fetcher evals（list のみ）
  doc-fetcher の list 実行が必要なプロンプトでは実行し、
  不要なプロンプトでは実行しないことを検証する。

  シナリオ: list-01 は list を実行する
    前提 doc-fetcher eval ケース "list-01" のプロンプト:
      """
      次のコマンドをそのまま実行して: skills/doc-fetcher/scripts/doc_fetcher.rb --list
      """
    もし Codex でプロンプトを実行する
    ならば list コマンドが有効に実行されている
    かつ list コマンドに --all や --id が含まれない

  シナリオ: list-02 は list を実行する
    前提 doc-fetcher eval ケース "list-02" のプロンプト:
      """
      次のコマンドをそのまま実行して: skills/doc-fetcher/scripts/doc_fetcher.rb --list
      """
    もし Codex でプロンプトを実行する
    ならば list コマンドが有効に実行されている
    かつ list コマンドに --all や --id が含まれない

  シナリオ: list-03 は list を実行する
    前提 doc-fetcher eval ケース "list-03" のプロンプト:
      """
      書き込み不要。次のコマンドだけ実行して一覧表示して: skills/doc-fetcher/scripts/doc_fetcher.rb --list
      """
    もし Codex でプロンプトを実行する
    ならば list コマンドが有効に実行されている
    かつ list コマンドに --all や --id が含まれない

  シナリオ: list-04 は list を実行する
    前提 doc-fetcher eval ケース "list-04" のプロンプト:
      """
      次のコマンドだけ実行して: skills/doc-fetcher/scripts/doc_fetcher.rb --list
      """
    もし Codex でプロンプトを実行する
    ならば list コマンドが有効に実行されている
    かつ list コマンドに --all や --id が含まれない

  シナリオ: list-05 は list を実行する
    前提 doc-fetcher eval ケース "list-05" のプロンプト:
      """
      state.json の sources 一覧を次のコマンドで表示して: skills/doc-fetcher/scripts/doc_fetcher.rb --list
      """
    もし Codex でプロンプトを実行する
    ならば list コマンドが有効に実行されている
    かつ list コマンドに --all や --id が含まれない

  シナリオ: list-06 は list を実行する
    前提 doc-fetcher eval ケース "list-06" のプロンプト:
      """
      anthropic の sources を list: skills/doc-fetcher/scripts/doc_fetcher.rb --list
      """
    もし Codex でプロンプトを実行する
    ならば list コマンドが有効に実行されている
    かつ list コマンドに --all や --id が含まれない

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
