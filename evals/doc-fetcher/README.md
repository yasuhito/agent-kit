# doc-fetcher evals（list のみ）

`skills/doc-fetcher` に対する Cucumber ベースの eval です。state のソース一覧を求められたときに
エージェントが `--list` を実行するかどうか、および無関係なプロンプトで実行しないことを検証します。

## 実行

```bash
./evals/doc-fetcher/run.sh
```

## チェック内容

- list を求めるプロンプト -> `skills/doc-fetcher/scripts/doc_fetcher.rb --list` が実行される
- 無関係なプロンプト -> `--list` は実行されない
- `--list` と `--all` / `--id` の併用は不許可

## 備考

- 決定論的・書き込みなしの eval です。fetch や snapshot は行いません。
- 次の拡張候補: `--dry-run` の追加、またはローカル HTTP fixture による fetch チェック。
