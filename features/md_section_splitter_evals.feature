# language: ja

機能: md-section-splitter evals（list のみ）
  md-section-splitter の list 実行が必要なプロンプトでは実行し、
  不要なプロンプトでは実行しないことを検証する。

  シナリオ: list: 登録済みソースを一覧表示する
    前提 md-section-splitter eval ケース "list-registered-sources" のプロンプト:
      """
      md-section-splitter の登録済みソース一覧を出して
      """
    もし Codex でプロンプトを実行する
    ならば list コマンドが有効に実行されている

  シナリオ: list: 分割対象のソース一覧を表示する
    前提 md-section-splitter eval ケース "list-split-targets" のプロンプト:
      """
      md-section-splitter の分割対象ソース一覧を見せて
      """
    もし Codex でプロンプトを実行する
    ならば list コマンドが有効に実行されている

  シナリオ: no: 要約依頼では list を実行しない
    前提 md-section-splitter eval ケース "no-summary-request" のプロンプト:
      """
      docs/best-practices を要約して
      """
    もし Codex でプロンプトを実行する
    ならば list コマンドが実行されていない
