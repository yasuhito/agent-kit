# language: ja

機能: md-converter evals（list のみ）
  md-converter の list 実行が必要なプロンプトでは実行し、
  不要なプロンプトでは実行しないことを検証する。

  シナリオ: list: 登録済みソースを一覧表示する
    前提 md-converter eval ケース "list-registered-sources" のプロンプト:
      """
      md-converter の登録済みソース一覧を出して
      """
    もし Codex でプロンプトを実行する
    ならば list コマンドが有効に実行されている

  シナリオ: list: 変換対象のソース一覧を表示する
    前提 md-converter eval ケース "list-convert-targets" のプロンプト:
      """
      md-converter の変換対象ソース一覧を見せて
      """
    もし Codex でプロンプトを実行する
    ならば list コマンドが有効に実行されている

  シナリオ: no: 変換の依頼では list を実行しない
    前提 md-converter eval ケース "no-convert-request" のプロンプト:
      """
      md-converter で変換して
      """
    もし Codex でプロンプトを実行する
    ならば list コマンドが実行されていない

  シナリオ: no: 要約依頼では list を実行しない
    前提 md-converter eval ケース "no-summary-request" のプロンプト:
      """
      README.md を要約して
      """
    もし Codex でプロンプトを実行する
    ならば list コマンドが実行されていない
