# language: ja

機能: md-normalizer evals（list のみ）
  md-normalizer の list 実行が必要なプロンプトでは実行し、
  不要なプロンプトでは実行しないことを検証する。

  シナリオ: list: 登録済みソースを一覧表示する
    前提 md-normalizer eval ケース "list-registered-sources" のプロンプト:
      """
      md-normalizer の登録済みソース一覧を出して
      """
    もし Codex でプロンプトを実行する
    ならば list コマンドが有効に実行されている

  シナリオ: list: 正規化対象のソース一覧を表示する
    前提 md-normalizer eval ケース "list-normalize-targets" のプロンプト:
      """
      md-normalizer の正規化対象ソース一覧を見せて
      """
    もし Codex でプロンプトを実行する
    ならば list コマンドが有効に実行されている

  シナリオ: no: 正規化の依頼では list を実行しない
    前提 md-normalizer eval ケース "no-normalize-request" のプロンプト:
      """
      md-normalizer で正規化して
      """
    もし Codex でプロンプトを実行する
    ならば list コマンドが実行されていない

  シナリオ: no: 要約依頼では list を実行しない
    前提 md-normalizer eval ケース "no-summary-request" のプロンプト:
      """
      README.md を要約して
      """
    もし Codex でプロンプトを実行する
    ならば list コマンドが実行されていない
