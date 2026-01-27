出典: https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-4-best-practices.md
スナップショット: 5945216cb8f4dc746276ada5b7fbf2a61b180c3ff32abc0a7c786e5774d52857
最終取得: 2026-01-25T03:48:53Z

# プロンプトのベストプラクティス

---

このガイドでは、Claude 4.x モデル向けの具体的なプロンプトエンジニアリング手法を、Sonnet 4.5、Haiku 4.5、Opus 4.5 に関する具体的な指針とともに紹介します。これらのモデルは、以前の Claude モデル世代よりも、より正確に指示に従うように訓練されています。
> **ヒント:**
> Claude 4.5 の新機能の概要は [What's new in Claude 4.5](/docs/en/about-claude/models/whats-new-claude-4-5) を、以前のモデルからの移行ガイドは [Migrating to Claude 4.5](/docs/en/about-claude/models/migrating-to-claude-4) を参照してください。

## 一般原則

### 指示を明確にする

Claude 4.x モデルは、明確で具体的な指示にうまく反応します。望む出力を具体的に示すことで、結果を向上させられます。従来の Claude モデルに見られた「期待以上の振る舞い」を求める場合は、新しいモデルではそのような振る舞いをより明示的に要求する必要があるかもしれません。

**例: 分析ダッシュボードの作成**

**あまり効果的ではない:**
```text
Create an analytics dashboard
```

**より効果的:**
```text
Create an analytics dashboard. Include as many relevant features and interactions as possible. Go beyond the basics to create a fully-featured implementation.
```

### 文脈を追加して性能を向上させる

指示の背景や動機（なぜその振る舞いが重要なのかを Claude に説明するなど）を与えることで、Claude 4.x モデルは目標をよりよく理解し、より的確な応答を返せるようになります。

**例: フォーマットの好み**

**あまり効果的ではない:**
```text
NEVER use ellipses
```

**より効果的:**
```text
Your response will be read aloud by a text-to-speech engine, so never use ellipses since the text-to-speech engine will not know how to pronounce them.
```

Claude は、その説明から十分に一般化できます。

### 例と詳細に細心の注意を払う

Claude 4.x モデルは、正確な指示追従能力の一環として、詳細や例に細心の注意を払います。望ましい振る舞いに合致する例を用意し、避けたい振る舞いを最小限に抑えるようにしてください。

### 長期的推論と状態トラッキング

Claude 4.5 モデルは、卓越した状態トラッキング能力により、長期的な推論タスクを得意とします。すべてを一度に試みるのではなく、少数の事柄に段階的に取り組み、着実に前進することで、長いセッションでも見通しを維持します。この能力は、複数のコンテキストウィンドウやタスクの反復を通じて特に発揮され、Claude は複雑なタスクに取り組み、状態を保存し、新しいコンテキストウィンドウで続行できます。

#### コンテキスト認識とマルチウィンドウのワークフロー

Claude 4.5 モデルは [コンテキスト認識](/docs/en/build-with-claude/context-windows#context-awareness-in-claude-sonnet-4-5) を備えており、会話全体を通じて残りのコンテキストウィンドウ（すなわち「トークン予算」）を追跡できます。これにより、Claude は作業スペースの残量を理解しながら、タスクを実行しコンテキストをより効果的に管理できます。

**コンテキスト制限の管理:**

コンテキストの圧縮や外部ファイルへの保存（Claude Code のように）を許可するエージェントハーネスで Claude を使用している場合は、その情報をプロンプトに追加して、Claude がそれに応じて振る舞えるようにすることをお勧めします。そうでない場合、Claude はコンテキストの上限に近づくと、自然と作業をまとめようとすることがあります。以下はプロンプトの例です:

```text Sample prompt
Your context window will be automatically compacted as it approaches its limit, allowing you to continue working indefinitely from where you left off. Therefore, do not stop tasks early due to token budget concerns. As you approach your token budget limit, save your current progress and state to memory before the context window refreshes. Always be as persistent and autonomous as possible and complete tasks fully, even if the end of your budget is approaching. Never artificially stop any task early regardless of the context remaining.
```

[メモリツール](/docs/en/agents-and-tools/tool-use/memory-tool) は、コンテキスト認識と自然に組み合わさり、シームレスなコンテキスト遷移を実現します。

#### 複数コンテキストウィンドウのワークフロー

複数のコンテキストウィンドウにまたがるタスクの場合:

1. **最初のコンテキストウィンドウには別のプロンプトを使う**: 最初のコンテキストウィンドウではフレームワークの準備（テスト作成、セットアップスクリプトの作成）を行い、その後のコンテキストウィンドウでは TODO リストに従って反復します。

2. **構造化形式でテストを書かせる**: 作業を始める前に Claude にテストを作らせ、それらを（例: `tests.json` のような）構造化形式で管理させます。これにより、長期的な反復能力が向上します。テストの重要性も念押ししてください: 「テストを削除したり編集したりするのは許容されません。これは機能の欠落やバグにつながる可能性があります。」

3. **作業効率向上のツールを整える**: サーバー起動、テストスイートやリンターの実行を円滑に行えるように、セットアップスクリプト（例: `init.sh`）の作成を促します。これにより、新しいコンテキストウィンドウで再開する際の重複作業を防げます。

4. **白紙から始めるか、圧縮するか**: コンテキストウィンドウがクリアされたら、圧縮を使うのではなく全く新しいコンテキストウィンドウから始めることを検討してください。Claude 4.5 モデルはローカルファイルシステムから状態を発見するのが非常に得意です。場合によっては、圧縮よりもこの能力を活用したほうが良いことがあります。開始方法については具体的に指示してください:
   - 「pwd を実行してください。このディレクトリ内のファイルのみ読み書きできます。」
   - 「progress.txt、tests.json、git のログを確認してください。」
   - 「新機能の実装に進む前に、基本的な統合テストを手作業で一通り実行してください。」

5. **検証ツールを用意する**: 自律タスクの長さが増すほど、継続的な人間からのフィードバックなしに正しさを検証する必要があります。UI のテスト用に Playwright MCP サーバーやコンピュータ使用機能などのツールが役立ちます。

6. **コンテキストを十分に使い切るよう促す**: Claude に、移る前にコンポーネントを効率的に完了させるよう促します:

```text Sample prompt
This is a very long task, so it may be beneficial to plan out your work clearly. It's encouraged to spend your entire output context working on the task - just make sure you don't run out of context with significant uncommitted work. Continue working systematically until you have completed this task.
```

#### 状態管理のベストプラクティス

- **状態データには構造化形式を使う**: 構造化情報（テスト結果やタスクの状態など）を追跡する際は、JSON などの構造化形式を使って、Claude がスキーマ要件を理解しやすいようにする
- **進捗メモには非構造化テキストを使う**: 自由形式の進捗メモは、一般的な進捗やコンテキストの記録に適している
- **状態トラッキングには git を使う**: git は、実施内容のログと復元可能なチェックポイントを提供します。Claude 4.5 モデルは、複数セッションにわたる状態トラッキングに git を特にうまく活用します。
- **漸進的な前進を強調する**: Claude に進捗を記録し、漸進的な作業に集中するよう明示的に依頼する

**例: 状態トラッキング**

```json
// Structured state file (tests.json)
{
  "tests": [
    {"id": 1, "name": "authentication_flow", "status": "passing"},
    {"id": 2, "name": "user_management", "status": "failing"},
    {"id": 3, "name": "api_endpoints", "status": "not_started"}
  ],
  "total": 200,
  "passing": 150,
  "failing": 25,
  "not_started": 25
}
```

```text
// Progress notes (progress.txt)
Session 3 progress:
- Fixed authentication token validation
- Updated user model to handle edge cases
- Next: investigate user_management test failures (test #2)
- Note: Do not remove tests as this could lead to missing functionality
```

### コミュニケーションスタイル

Claude 4.5 モデルは、以前のモデルと比べて、より簡潔で自然なコミュニケーションスタイルです:

- **より直接的で地に足の着いた**: 自己賛美的な更新ではなく、事実に基づく進捗レポートを提供
- **より会話的**: やや流暢で口語的になり、機械的ではない
- **より簡潔**: 要求されない限り、効率性のために詳細な要約を省く場合がある

このコミュニケーションスタイルは、不要な冗長さなしに、達成した内容を正確に反映します。

## 特定の状況におけるガイダンス

### 冗長さのバランスを取る

Claude 4.5 モデルは効率性に傾く傾向があり、ツール呼び出しの後で口頭の要約を省略し、次のアクションに直接進むことがあります。これはワークフローを合理化しますが、思考過程の見える化を望む場合もあるでしょう。

作業中の更新を Claude に提供させたい場合は:

```text Sample prompt
After completing a task that involves tool use, provide a quick summary of the work you've done.
```

### ツール使用パターン

Claude 4.5 モデルは正確な指示追従に優れており、特定のツール使用について明示的な指示から恩恵を受けます。「いくつか変更を提案してもらえますか」と言うと、たとえ変更の実施を意図していても、提案のみを行う場合があります。

Claude に実行させるには、より明確に指示してください:

**例: 明示的な指示**

**あまり効果的ではない（Claude は提案だけを行う）:**
```text
Can you suggest some changes to improve this function?
```

**より効果的（Claude が実際に変更を行う）:**
```text
Change this function to improve its performance.
```

または:
```text
Make these edits to the authentication flow.
```

Claude にデフォルトでより積極的に行動させたい場合は、以下をシステムプロンプトに追加できます:

```text Sample prompt for proactive action
<default_to_action>
By default, implement changes rather than only suggesting them. If the user's intent is unclear, infer the most useful likely action and proceed, using tools to discover any missing details instead of guessing. Try to infer the user's intent about whether a tool call (e.g., file edit or read) is intended or not, and act accordingly.
</default_to_action>
```

逆に、モデルをデフォルトでより慎重にし、すぐに実装に飛びつかず、要求された場合のみ行動させたい場合は、以下のようなプロンプトでこの振る舞いを誘導できます:

```text Sample prompt for conservative action
<do_not_act_before_instructions>
Do not jump into implementatation or changes files unless clearly instructed to make changes. When the user's intent is ambiguous, default to providing information, doing research, and providing recommendations rather than taking action. Only proceed with edits, modifications, or implementations when the user explicitly requests them.
</do_not_act_before_instructions>
```

### ツールの使用とトリガー

Claude Opus 4.5 は以前のモデルよりもシステムプロンプトに敏感です。ツールやスキルのアンダートリガーを減らすために設計したプロンプトを使用している場合、Claude Opus 4.5 では今度はオーバートリガーする可能性があります。修正策は、強い言い回しを和らげることです。以前は「重要: 必ずこのツールを使うこと…」と言っていたところを、「このツールは…の場合に使ってください」のような通常のプロンプトにできます。

### 応答の形式を制御する

Claude 4.x モデルで出力フォーマットを誘導する際に、特に効果的だとわかっている方法がいくつかあります:

1. **してほしくないことではなく、してほしいことを伝える**

   - 例: 「応答で markdown を使わないでください」ではなく
   - 「応答は、滑らかに流れる散文の段落で構成してください」のように伝える

2. **XML 形式のインジケータを使う**

   - 例: 「応答の散文部分は \<smoothly_flowing_prose_paragraphs\> タグ内に書いてください。」

3. **プロンプトのスタイルを望む出力に合わせる**

   プロンプトで使用するフォーマットスタイルは、Claude の応答スタイルに影響する場合があります。出力フォーマットの誘導にまだ課題がある場合は、望む出力スタイルにできるだけプロンプトを合わせることをお勧めします。例えば、プロンプトから markdown を取り除くと、出力中の markdown の量を減らせます。

4. **特定のフォーマットの好みには詳細なプロンプトを使う**

   markdown やフォーマットの使用をより細かく制御するには、明示的な指示を与えてください:

```text Sample prompt to minimize markdown
<avoid_excessive_markdown_and_bullet_points>
When writing reports, documents, technical explanations, analyses, or any long-form content, write in clear, flowing prose using complete paragraphs and sentences. Use standard paragraph breaks for organization and reserve markdown primarily for `inline code`, code blocks (```...```), and simple headings (###, and ###). Avoid using **bold** and *italics*.

DO NOT use ordered lists (1. ...) or unordered lists (*) unless : a) you're presenting truly discrete items where a list format is the best option, or b) the user explicitly requests a list or ranking

Instead of listing items with bullets or numbers, incorporate them naturally into sentences. This guidance applies especially to technical writing. Using prose instead of excessive formatting will improve user satisfaction. NEVER output a series of overly short bullet points.

Your goal is readable, flowing text that guides the reader naturally through ideas rather than fragmenting information into isolated points.
</avoid_excessive_markdown_and_bullet_points>
```

### リサーチと情報収集

Claude 4.5 モデルは卓越した自律的検索能力を示し、複数のソースから情報を効果的に発見・統合できます。最適なリサーチ結果のために:

1. **明確な成功条件を与える**: リサーチ質問に対する成功の基準を定義する

2. **ソースの検証を促す**: 複数のソースで情報を検証するよう Claude に依頼する

3. **複雑なリサーチタスクには構造化したアプローチを使う**:

```text Sample prompt for complex research
Search for this information in a structured way. As you gather data, develop several competing hypotheses. Track your confidence levels in your progress notes to improve calibration. Regularly self-critique your approach and plan. Update a hypothesis tree or research notes file to persist information and provide transparency. Break down this complex research task systematically.
```

この構造化アプローチにより、Claude はあらゆる規模のコーパスでも、ほぼすべての情報を見つけて統合し、所見を反復的に吟味できるようになります。

### サブエージェントのオーケストレーション

Claude 4.5 モデルは、ネイティブなサブエージェントのオーケストレーション能力が大幅に向上しています。これらのモデルは、タスクが専門サブエージェントに委譲したほうが有利な場合を認識し、明示的な指示がなくても積極的に実行します。

この振る舞いを活かすには:

1. **よく定義されたサブエージェントツールを用意する**: サブエージェントのツールをツール定義で利用可能にし、説明を付す
2. **Claude に自然にオーケストレーションさせる**: 明示的な指示がなくても、Claude は適切に委譲します
3. **必要に応じて慎重さを調整する**:

```text Sample prompt for conservative subagent usage
Only delegate to subagents when the task clearly benefits from a separate agent with a new context window.
```

### モデルの自己認識

アプリケーション内で Claude に正しく自己を識別させたり、特定の API 文字列を使用させたい場合は:

```text Sample prompt for model identity
The assistant is Claude, created by Anthropic. The current model is Claude Sonnet 4.5.
```

LLM 駆動のアプリでモデル文字列を指定する必要がある場合:

```text Sample prompt for model string
When an LLM is needed, please default to Claude Sonnet 4.5 unless the user requests otherwise. The exact model string for Claude Sonnet 4.5 is claude-sonnet-4-5-20250929.
```

### 「思考」への感度

拡張思考が無効な場合、Claude Opus 4.5 は「think」という語やその派生語に特に敏感です。「think」を「consider（検討する）」「believe（考える）」「evaluate（評価する）」など、同様の意味を伝える別の語に置き換えることを推奨します。

### 思考とインタリーブ思考機能を活用する

Claude 4.x モデルは、ツール使用後の省察や複雑な多段推論を伴うタスクで特に有用な思考機能を提供します。初期の思考やインタリーブされた思考を誘導することで、より良い結果を得られます。

```text Example prompt
After receiving tool results, carefully reflect on their quality and determine optimal next steps before proceeding. Use your thinking to plan and iterate based on this new information, and then take the best next action.
```

> **情報:**
> 思考機能の詳細は [Extended thinking](/docs/en/build-with-claude/extended-thinking) を参照してください。

### ドキュメント作成

Claude 4.5 モデルは、プレゼンテーション、アニメーション、ビジュアルドキュメントの作成に優れています。これらのモデルは、この領域で Claude Opus 4.1 に匹敵またはそれ以上の性能を発揮し、創造性に富み、指示追従も強化されています。多くの場合、初回から洗練され実用的な出力を生成します。

ドキュメント作成で最良の結果を得るには:

```text Sample prompt
Create a professional presentation on [topic]. Include thoughtful design elements, visual hierarchy, and engaging animations where appropriate.
```

### ビジョン機能の向上

Claude Opus 4.5 は、以前の Claude モデルと比べてビジョン機能が向上しています。特に、コンテキスト内に複数の画像がある場合の画像処理やデータ抽出タスクで優れた性能を発揮します。この改善はコンピュータ使用にも及び、スクリーンショットや UI 要素をより確実に解釈できます。動画をフレームに分割して分析することも可能です。

さらに性能を高める効果的な手法として、Claude Opus 4.5 にクロップツールや[スキル](/docs/en/agents-and-tools/agent-skills/overview)を与えることがあります。画像の関連領域に「ズーム」できると、評価精度が一貫して向上することを確認しています。クロップツールのクックブックは[こちら](https://platform.claude.com/cookbook/multimodal-crop-tool)にまとめています。

### 並列ツール呼び出しの最適化

Claude 4.x モデルは並列ツール実行を得意としており、特に Sonnet 4.5 は複数の操作を同時に積極的に起動します。Claude 4.x モデルは次のようなことを行います:

- リサーチ中に複数の推測検索を並行して実行
- コンテキスト構築を速めるために複数ファイルを同時に読む
- bash コマンドを並列実行（システム性能がボトルネックになることも）

この挙動は容易に誘導可能です。プロンプトなしでも並列ツール呼び出しの成功率は高いですが、ほぼ 100% に引き上げたり、積極性のレベルを調整できます:

```text Sample prompt for maximum parallel efficiency
<use_parallel_tool_calls>
If you intend to call multiple tools and there are no dependencies between the tool calls, make all of the independent tool calls in parallel. Prioritize calling tools simultaneously whenever the actions can be done in parallel rather than sequentially. For example, when reading 3 files, run 3 tool calls in parallel to read all 3 files into context at the same time. Maximize use of parallel tool calls where possible to increase speed and efficiency. However, if some tool calls depend on previous calls to inform dependent values like the parameters, do NOT call these tools in parallel and instead call them sequentially. Never use placeholders or guess missing parameters in tool calls.
</use_parallel_tool_calls>
```

```text Sample prompt to reduce parallel execution
Execute operations sequentially with brief pauses between each step to ensure stability.
```

### エージェント的コーディングにおけるファイル作成の削減

Claude 4.x モデルは、特にコードを扱う際、テストや反復のために新しいファイルを作成することがあります。これは、特に Python スクリプトなどのファイルを最終出力を保存する前の「一時的な下書き場」として用いるためです。一時ファイルの使用は、エージェント的コーディングのユースケースで成果を向上させることがあります。

新規ファイルの作成を最小限に抑えたい場合は、後片付けを行うよう Claude に指示できます:

```text Sample prompt
If you create any temporary new files, scripts, or helper files for iteration, clean up these files by removing them at the end of the task.
```

### 過剰な意欲とファイル作成

Claude Opus 4.5 は、追加のファイルを作成したり、不要な抽象化を導入したり、求められていない柔軟性を持ち込んだりと、過剰設計になりがちです。この望ましくない挙動が見られる場合は、解法をミニマルに保つよう明示的に促してください。

例えば:

```text Sample prompt to minimize overengineering
Avoid over-engineering. Only make changes that are directly requested or clearly necessary. Keep solutions simple and focused.

Don't add features, refactor code, or make "improvements" beyond what was asked. A bug fix doesn't need surrounding code cleaned up. A simple feature doesn't need extra configurability.

Don't add error handling, fallbacks, or validation for scenarios that can't happen. Trust internal code and framework guarantees. Only validate at system boundaries (user input, external APIs). Don't use backwards-compatibility shims when you can just change the code.

Don't create helpers, utilities, or abstractions for one-time operations. Don't design for hypothetical future requirements. The right amount of complexity is the minimum needed for the current task. Reuse existing abstractions where possible and follow the DRY principle.
```

### フロントエンドデザイン

Claude 4.x モデル、とりわけ Opus 4.5 は、実世界の複雑な Web アプリケーションの構築と優れたフロントエンドデザインに長けています。ただし、指針がないと、モデルは一般的なパターンに流れ、「AI 的で味気ない」見た目に陥りがちです。驚きや喜びを与える独創的でクリエイティブなフロントエンドを作るには:

> **ヒント:**
> フロントエンドデザインを改善する詳細ガイドは、[improving frontend design through skills](https://www.claude.com/blog/improving-frontend-design-through-skills) のブログ記事を参照してください。

より良いフロントエンドデザインを促すために使えるシステムプロンプトのスニペットはこちらです:

```text Sample prompt for frontend aesthetics
<frontend_aesthetics>
You tend to converge toward generic, "on distribution" outputs. In frontend design, this creates what users call the "AI slop" aesthetic. Avoid this: make creative, distinctive frontends that surprise and delight.

Focus on:
- Typography: Choose fonts that are beautiful, unique, and interesting. Avoid generic fonts like Arial and Inter; opt instead for distinctive choices that elevate the frontend's aesthetics.
- Color & Theme: Commit to a cohesive aesthetic. Use CSS variables for consistency. Dominant colors with sharp accents outperform timid, evenly-distributed palettes. Draw from IDE themes and cultural aesthetics for inspiration.
- Motion: Use animations for effects and micro-interactions. Prioritize CSS-only solutions for HTML. Use Motion library for React when available. Focus on high-impact moments: one well-orchestrated page load with staggered reveals (animation-delay) creates more delight than scattered micro-interactions.
- Backgrounds: Create atmosphere and depth rather than defaulting to solid colors. Layer CSS gradients, use geometric patterns, or add contextual effects that match the overall aesthetic.

Avoid generic AI-generated aesthetics:
- Overused font families (Inter, Roboto, Arial, system fonts)
- Clichéd color schemes (particularly purple gradients on white backgrounds)
- Predictable layouts and component patterns
- Cookie-cutter design that lacks context-specific character

Interpret creatively and make unexpected choices that feel genuinely designed for the context. Vary between light and dark themes, different fonts, different aesthetics. You still tend to converge on common choices (Space Grotesk, for example) across generations. Avoid this: it is critical that you think outside the box!
</frontend_aesthetics>
```

完全なスキルは [こちら](https://github.com/anthropics/claude-code/blob/main/plugins/frontend-design/skills/frontend-design/SKILL.md) も参照できます。

### テスト合格への過度な集中とハードコーディングを避ける

Claude 4.x モデルは、テストを合格させることに偏重し、より一般的な解決策を犠牲にすることがあったり、複雑なリファクタリングで標準ツールを直接使うのではなく補助スクリプトなどの回避策に頼ることがあります。この挙動を防ぎ、堅牢で汎用的な解法を確保するために:

```text Sample prompt
Please write a high-quality, general-purpose solution using the standard tools available. Do not create helper scripts or workarounds to accomplish the task more efficiently. Implement a solution that works correctly for all valid inputs, not just the test cases. Do not hard-code values or create solutions that only work for specific test inputs. Instead, implement the actual logic that solves the problem generally.

Focus on understanding the problem requirements and implementing the correct algorithm. Tests are there to verify correctness, not to define the solution. Provide a principled implementation that follows best practices and software design principles.

If the task is unreasonable or infeasible, or if any of the tests are incorrect, please inform me rather than working around them. The solution should be robust, maintainable, and extendable.
```

### コード探索を促す

Claude Opus 4.5 は非常に高性能ですが、コード探索において過度に慎重になることがあります。コードを読まずに解決策を提案したり、読んでいないコードについて仮定を置く傾向に気づいた場合は、プロンプトに明示的な指示を追加するのが最善策です。Claude Opus 4.5 はこれまでで最も誘導しやすいモデルであり、直接的な指示に確実に反応します。

例えば:

```text Sample prompt for code exploration
ALWAYS read and understand relevant files before proposing code edits. Do not speculate about code you have not inspected. If the user references a specific file/path, you MUST open and inspect it before explaining or proposing fixes. Be rigorous and persistent in searching code for key facts. Thoroughly review the style, conventions, and abstractions of the codebase before implementing new features or abstractions.
```

### エージェント的コーディングにおけるハルシネーションの最小化

Claude 4.x モデルはハルシネーションが起きにくく、コードに基づいたより正確で根拠のある賢い回答を返します。この挙動をさらに促し、ハルシネーションを最小化するには:

```text Sample prompt
<investigate_before_answering>
Never speculate about code you have not opened. If the user references a specific file, you MUST read the file before answering. Make sure to investigate and read relevant files BEFORE answering questions about the codebase. Never make any claims about code before investigating unless you are certain of the correct answer - give grounded and hallucination-free answers.
</investigate_before_answering>
```

## 移行時の考慮事項

Claude 4.5 モデルへ移行する際は:

1. **望む挙動を具体的に示す**: 出力で見たいものを正確に記述することを検討してください。

2. **指示に修飾語を加える**: Claude に出力の品質や詳細を高めるよう促す修飾語を加えると、性能をより良く形作れます。例えば、「分析ダッシュボードを作成して」ではなく、「分析ダッシュボードを作成してください。関連する機能やインタラクションは可能な限り含めてください。基本を超えて、フル機能の実装を目指してください。」のようにします。

3. **特定の機能は明示的に要求する**: アニメーションやインタラクティブな要素が必要な場合は、明示的にリクエストしてください。
