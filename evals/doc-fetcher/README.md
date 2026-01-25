# doc-fetcher evals（list のみ）

`skills/doc-fetcher` に対する最小の eval ハーネスです。state のソース一覧を求められたときに
エージェントが `--list` を実行するかどうか、および無関係なプロンプトで実行しないことを検証します。

## 実行

```bash
./evals/doc-fetcher/run.sh
ruby ./evals/doc-fetcher/check.rb
```

## チェック内容

- should_trigger=1 -> `skills/doc-fetcher/scripts/doc_fetcher.rb --list` が少なくとも 1 回実行されていること
- should_trigger=0 -> `--list` が一度も実行されていないこと
- `--list` と `--all` / `--id` の併用は不許可

## 備考

- 決定論的・書き込みなしの eval です。fetch や snapshot は行いません。
- 次の拡張候補: `--dry-run --id` の追加、またはローカル HTTP fixture による fetch チェック。
