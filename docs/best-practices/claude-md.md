# CLAUDE.md ベストプラクティス

Source: https://code.claude.com/docs/en/best-practices.md
Snapshot: 48965cf2ee49f219ed211e5260cfc74c50226648e752116ae90a77ca6b95610c
Last fetched: 2026-01-24T06:47:57Z

## 効果的な CLAUDE.md を書く

> ヒント:
> 現在のプロジェクト構造に基づいたスターター CLAUDE.md を生成するには `/init` を実行し、その後時間をかけて磨き込んでください。

CLAUDE.md は、Claude が各会話の開始時に読む特別なファイルです。Bash コマンド、コードスタイル、ワークフローのルールを含めましょう。これにより、Claude に対して、コードだけからは得られない永続的なコンテキストを提供できます。つまり、**コードだけからは推論できない**情報を与えられます。

`/init` コマンドは、コードベースを解析してビルドシステム、テストフレームワーク、コードパターンを検出し、洗練させるための堅実な土台を提供します。

CLAUDE.md に必須の形式はありませんが、短く人間が読みやすいものにしましょう。例えば:

```markdown CLAUDE.md theme={null}
# Code style
- Use ES modules (import/export) syntax, not CommonJS (require)
- Destructure imports when possible (eg. import { foo } from 'bar')

# Workflow
- Be sure to typecheck when you're done making a series of code changes
- Prefer running single tests, and not the whole test suite, for performance
```

CLAUDE.md は毎セッション読み込まれるため、幅広く適用できる事項だけを含めてください。ドメイン知識や状況によってのみ関連するワークフローは、代わりに[スキル](/en/skills)を使いましょう。Claude はそれらをオンデマンドで読み込み、すべての会話を肥大化させません。

簡潔に保ちましょう。各行について「これを削除したら Claude は間違えるだろうか？」と自問してください。もしそうでないなら削除しましょう。*これがなければ Claude がミスをするだろうか？* そうでなければ削ってください。肥大化した CLAUDE.md は、Claude が実際の指示を無視する原因になります！

| ✅ 含める                                           | ❌ 除外                                              |
| ---------------------------------------------------- | ---------------------------------------------------- |
| Claude が推測できない Bash コマンド                 | コードを読めば Claude が把握できること               |
| デフォルトと異なるコードスタイル規則                | Claude がすでに知っている標準的な言語規約            |
| テスト手順と推奨テストランナー                      | 詳細な API ドキュメント（代わりにドキュメントへリンク） |
| リポジトリの作法（ブランチ命名、PR の慣習）         | 頻繁に変わる情報                                     |
| プロジェクト特有のアーキテクチャ上の決定            | 長い解説やチュートリアル                             |
| 開発環境の癖（必須の環境変数）                      | コードベースのファイルごとの説明                     |
| よくある落とし穴や分かりにくい挙動                  | 「クリーンなコードを書け」のような自明なプラクティス |

望まないことを Claude がし続け、抑止するルールを書いているのに改善されない場合、ファイルが長すぎて重要なルールがノイズに埋もれている可能性があります。CLAUDE.md に答えがある質問を Claude がしてくるなら、表現が曖昧なのかもしれません。CLAUDE.md をコードのように扱いましょう。問題が起きたらレビューし、定期的に刈り込み、変更によって Claude の挙動が実際に変わるか観察してテストしてください。

遵守率を高めるには、"IMPORTANT" や "YOU MUST" などの強調を加えて指示を調整できます。CLAUDE.md は git にコミットしてチームで共同編集しましょう。時間とともに価値が複利的に蓄積されます。

CLAUDE.md は `@path/to/import` 構文で追加ファイルをインポートできます:

```markdown CLAUDE.md theme={null}
See @README.md for project overview and @package.json for available npm commands.

# Additional Instructions
- Git workflow: @docs/git-instructions.md
- Personal overrides: @~/.claude/my-project-instructions.md
```

CLAUDE.md は次の場所に配置できます:

* **ホームフォルダ (`~/.claude/CLAUDE.md`)**: すべての Claude セッションに適用
* **プロジェクトルート (`./CLAUDE.md`)**: git にチェックインしてチームと共有するか、`CLAUDE.local.md` と名付けて `.gitignore` してください
* **親ディレクトリ**: `root/CLAUDE.md` と `root/foo/CLAUDE.md` の両方が自動的に取り込まれるモノレポで有用
* **子ディレクトリ**: そのディレクトリ内のファイルを扱うとき、Claude は必要に応じて子の CLAUDE.md を取り込みます

## よくある失敗パターン: 過剰に指定された CLAUDE.md

* **過剰に指定された CLAUDE.md。** CLAUDE.md が長すぎると、重要なルールがノイズに埋もれてしまうため、Claude はその半分を無視します。
  > **対策**: 容赦なく削りましょう。指示がなくても Claude が既に正しくできていることは削除するか、フックに変換してください。
