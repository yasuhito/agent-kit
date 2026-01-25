# md-normalizer evals（list のみ）

`skills/md-normalizer` に対する Cucumber ベースの eval です。自然文で一覧を求められたときに
エージェントが `list` を実行するかどうか、および無関係なプロンプトで実行しないことを検証します。

## 実行

```bash
./evals/md-normalizer/run.sh
```

## チェック内容

- list を求めるプロンプト -> `skills/md-normalizer/scripts/md_normalizer.rb list` が実行される
- 無関係なプロンプト -> `list` は実行されない

## 備考

- 決定論的・書き込みなしの eval です。
