ソース: https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-4-best-practices.md
スナップショット: 5945216cb8f4dc746276ada5b7fbf2a61b180c3ff32abc0a7c786e5774d52857
最終取得日時: 2026-01-24T22:05:35Z

# プロンプトのベストプラクティス

---

このガイドでは、Claude 4.x モデル向けの具体的なプロンプトエンジニアリング手法を紹介し、とりわけ Sonnet 4.5、Haiku 4.5、Opus 4.5 に関する指針を示します。これらのモデルは、従来世代の Claude よりも精密に指示に従うよう訓練されています。
> ヒント:
> Claude 4.5 の新機能の概要は[What's new in Claude 4.5](/docs/en/about-claude/models/whats-new-claude-4-5)をご覧ください。以前のモデルからの移行ガイダンスは[Migrating to Claude 4.5](/docs/en/about-claude/models/migrating-to-claude-4)を参照してください。

## 一般原則

### 指示は明確かつ具体的に

Claude 4.x モデルは明確で具体的な指示に良く反応します。望む出力を具体的に示すと結果が向上します。従来の Claude の「期待以上の」ふるまいを望む場合は、新しいモデルではその行動をより明示的に要求する必要があるかもしれません。

**例: 分析ダッシュボードの作成**

**あまり効果的でない:**
```text
Create an analytics dashboard
```

**より効果的:**
```text
Create an analytics dashboard. Include as many relevant features and interactions as possible. Go beyond the basics to create a fully-featured implementation.
```

### 文脈を加えて性能を高める

なぜその行動が重要かといった文脈や動機づけを説明すると、Claude 4.x モデルが目的をよりよく理解し、的を絞った応答を返しやすくなります。

**例: フォーマットの好み**

**あまり効果的でない:**
```text
NEVER use ellipses
```

**より効果的:**
```text
Your response will be read aloud by a text-to-speech engine, so never use ellipses since the text-to-speech engine will not know how to pronounce them.
```

Claude は説明から一般化するのに十分な賢さを備えています。

### 例と詳細には細心の注意を

Claude 4.x モデルは、精密な指示追従能力の一環として、例や細部に細心の注意を払います。望ましい行動を促し、避けたい行動を最小限にするよう、提示する例の整合性に注意してください。

### 長期的な推論と状態トラッキング

Claude 4.5 モデルは、長期的な推論タスクに秀で、優れた状態トラッキング能力を持ちます。すべてを一度に試みるのではなく、いくつかのことを着実に前進させることに集中して、長いセッションでも方針を保ちます。この能力は、複数のコンテキストウィンドウやタスクの反復を通じて特に発揮されます。Claude は複雑なタスクに取り組み、状態を保存し、新しいコンテキストウィンドウで作業を継続できます。

#### コンテキスト認識とマルチウィンドウのワークフロー

Claude 4.5 モデルは[コンテキスト認識](/docs/en/build-with-claude/context-windows#context-awareness-in-claude-sonnet-4-5)を備え、会話全体を通じて残りのコンテキストウィンドウ（すなわち「token budget」）を追跡できます。これにより、作業できるスペースを理解して、タスク実行とコンテキスト管理をより効果的に行えます。

**コンテキスト制限の管理:**

コンテキストを圧縮したり、外部ファイルにコンテキストの保存を許可したりするエージェントハーネス（Claude Code のような）で Claude を使う場合は、その情報をプロンプトに追加し、それに応じたふるまいができるようにすることを推奨します。そうでない場合、Claude はコンテキスト制限に近づくにつれて、自然に作業をまとめに入ろうとすることがあります。以下はそのためのプロンプト例です:

```text Sample prompt
Your context window will be automatically compacted as it approaches its limit, allowing you to continue working indefinitely from where you left off. Therefore, do not stop tasks early due to token budget concerns. As you approach your token budget limit, save your current progress and state to memory before the context window refreshes. Always be as persistent and autonomous as possible and complete tasks fully, even if the end of your budget is approaching. Never artificially stop any task early regardless of the context remaining.
```

[Memory tool](/docs/en/agents-and-tools/tool-use/memory-tool)はコンテキスト認識と相性がよく、シームレスなコンテキスト移行を実現します。

#### 複数のコンテキストウィンドウにまたがるワークフロー

複数のコンテキストウィンドウにまたがるタスクでは:

1. 最初のコンテキストウィンドウには別のプロンプトを使う: 最初のウィンドウではフレームワーク（テストの作成、セットアップスクリプトの作成）を整え、以降のウィンドウで todo リストに沿って反復します。

2. 構造化形式でテストを書かせる: 作業開始前にテストを作成させ、`tests.json` のような構造化フォーマットで管理します。これにより長期的な反復性能が向上します。テストの重要性をリマインドしてください。「テストを削除・編集するのは許容できません。欠落やバグのある機能につながる可能性があります。」

3. 快適さ向上のためのツールをセットアップ: サーバー起動、テストスイートやリンターの実行を円滑にするセットアップスクリプト（例: `init.sh`）の作成を促します。新しいコンテキストウィンドウで再開する際の繰り返し作業を防ぎます。

4. ゼロから始めるか圧縮するか: コンテキストウィンドウがクリアされた場合、圧縮を使うよりも、新しいコンテキストウィンドウでやり直すことを検討してください。Claude 4.5 モデルはローカルファイルシステムからの状態発見が非常に得意です。場合によっては、圧縮よりこの利点を活かしたいことがあります。開始方法を明確に指示してください:
   - "Call pwd; you can only read and write files in this directory."
   - "Review progress.txt, tests.json, and the git logs."
   - "Manually run through a fundamental integration test before moving on to implementing new features."

5. 検証ツールを提供する: 自律的なタスクが長くなるほど、継続的な人間のフィードバックなしに正しさを検証する必要があります。Playwright MCP サーバーや UI テストのためのコンピュータ操作機能などのツールが役立ちます。

6. コンテキストを十分に使い切るよう促す: 先に進む前に各コンポーネントを効率よく完成させるよう促します:

```text Sample prompt
This is a very long task, so it may be beneficial to plan out your work clearly. It's encouraged to spend your entire output context working on the task - just make sure you don't run out of context with significant uncommitted work. Continue working systematically until you have completed this task.
```

#### 状態管理のベストプラクティス

- 状態データには構造化フォーマットを使う: 構造化情報（テスト結果やタスクステータスなど）を追跡する際は、JSON などの構造化形式を用いて、スキーマ要件の理解を助けます
- 進捗ノートには非構造化テキストを使う: 自由形式の進捗メモは、一般的な進行状況やコンテキストの記録に適しています
- 状態トラッキングには git を使う: git は実施内容のログと、復元可能なチェックポイントを提供します。Claude 4.5 モデルは、複数セッションにまたがる状態トラッキングに git を特にうまく活用します。
- 漸進的な進捗を強調する: Claude に進捗を記録し、漸進的な作業に集中するよう明示的に依頼します

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

Claude 4.5 モデルは、以前のモデルと比べてより簡潔で自然なコミュニケーションスタイルです:

- より直接的で地に足のついた表現: 自己賛美的な更新ではなく、事実に基づく進捗報告を提供
- より会話的: やや流暢で口語的、機械的でない
- 冗長性が低い: 指示がない限り、効率のために詳細な要約を省くことがあります

このスタイルは、不要な説明を避けつつ、達成した内容を正確に反映します。

## 特定の状況向けのガイダンス

### 冗長さのバランスを取る

Claude 4.5 モデルは効率を重視する傾向があり、ツール呼び出し後の口頭での要約を省いて、次のアクションに直接進むことがあります。これはワークフローを合理化しますが、推論過程の可視性を高めたい場合もあるでしょう。

作業の途中経過を更新させたい場合:

```text Sample prompt
After completing a task that involves tool use, provide a quick summary of the work you've done.
```

### ツール使用パターン

Claude 4.5 モデルは精密な指示追従に訓練されており、特定のツールを使うよう明示的に指示されると効果を発揮します。「いくつか変更案を提案してくれる？」のように言うと、意図としては変更を実装してほしくても、提案のみを返すことがあります。

Claude に実際のアクションを取らせるには、より明確に指示してください:

**例: 明示的な指示**

**あまり効果的でない（Claude は提案のみ行う）:**
```text
Can you suggest some changes to improve this function?
```

**より効果的（Claude が変更を実装する）:**
```text
Change this function to improve its performance.
```

または:
```text
Make these edits to the authentication flow.
```

デフォルトでより積極的に行動させたい場合は、システムプロンプトに以下を追加できます:

```text Sample prompt for proactive action
<default_to_action>
By default, implement changes rather than only suggesting them. If the user's intent is unclear, infer the most useful likely action and proceed, using tools to discover any missing details instead of guessing. Try to infer the user's intent about whether a tool call (e.g., file edit or read) is intended or not, and act accordingly.
</default_to_action>
```

一方、デフォルトではより慎重に、すぐに実装に飛びつかず、要求されたときのみ行動させたい場合は、以下のようなプロンプトでこのふるまいを誘導できます:

```text Sample prompt for conservative action
<do_not_act_before_instructions>
Do not jump into implementatation or changes files unless clearly instructed to make changes. When the user's intent is ambiguous, default to providing information, doing research, and providing recommendations rather than taking action. Only proceed with edits, modifications, or implementations when the user explicitly requests them.
</do_not_act_before_instructions>
```

### ツール使用とトリガリング

Claude Opus 4.5 は、以前のモデルよりもシステムプロンプトに対して反応的です。ツールやスキルの過小トリガーを減らすために設計されたプロンプトを使っている場合、Claude Opus 4.5 では過剰トリガーが発生するかもしれません。対策は、強すぎる言い回しを弱めることです。以前は "CRITICAL: You MUST use this tool when..." と書いていたところを、"Use this tool when..." のような通常のプロンプトに置き換えてください。

### 応答の形式を制御する

Claude 4.x モデルで出力形式を誘導する際に特に有効だとわかっている方法がいくつかあります:

1. してほしくないことではなく、してほしいことを伝える

   - Instead of: "Do not use markdown in your response"
   - Try: "Your response should be composed of smoothly flowing prose paragraphs."

2. XML の形式インジケータを使う

   - Try: "Write the prose sections of your response in \<smoothly_flowing_prose_paragraphs\> tags."

3. 望む出力に合わせてプロンプトのスタイルを合わせる

   プロンプトで使うフォーマットのスタイルが、Claude の応答スタイルに影響する場合があります。出力フォーマットの誘導が依然として難しい場合は、可能な範囲でプロンプトのスタイルを望む出力スタイルに合わせることをおすすめします。例えば、プロンプトから Markdown を取り除くと、出力の Markdown の量を減らせます。

4. 特定のフォーマットの好みに対して詳細なプロンプトを使う

   Markdown やフォーマットの使用をより細かく制御したい場合は、明確なガイダンスを提供します:

```text Sample prompt to minimize markdown
<avoid_excessive_markdown_and_bullet_points>
When writing reports, documents, technical explanations, analyses, or any long-form content, write in clear, flowing prose using complete paragraphs and sentences. Use standard paragraph breaks for organization and reserve markdown primarily for `inline code`, code blocks (```...```), and simple headings (###, and ###). Avoid using **bold** and *italics*.

DO NOT use ordered lists (1. ...) or unordered lists (*) unless : a) you're presenting truly discrete items where a list format is the best option, or b) the user explicitly requests a list or ranking

Instead of listing items with bullets or numbers, incorporate them naturally into sentences. This guidance applies especially to technical writing. Using prose instead of excessive formatting will improve user satisfaction. NEVER output a series of overly short bullet points.

Your goal is readable, flowing text that guides the reader naturally through ideas rather than fragmenting information into isolated points.
</avoid_excessive_markdown_and_bullet_points>
```

### 調査と情報収集

Claude 4.5 モデルは卓越したエージェント的検索能力を示し、複数のソースから情報を効果的に発見・統合できます。最適な調査結果のために:

1. 明確な成功基準を提供する: 調査質問に対する成功の定義を明示します

2. ソースの検証を促す: 複数のソースで情報を検証するよう依頼します

3. 複雑な調査タスクには構造化アプローチを使う:

```text Sample prompt for complex research
Search for this information in a structured way. As you gather data, develop several competing hypotheses. Track your confidence levels in your progress notes to improve calibration. Regularly self-critique your approach and plan. Update a hypothesis tree or research notes file to persist information and provide transparency. Break down this complex research task systematically.
```

この構造化アプローチにより、Claude は事実上あらゆる情報を見つけて統合し、コーパスの大きさに関わらず反復的に批判的検討を行えます。

### サブエージェントのオーケストレーション

Claude 4.5 モデルは、ネイティブなサブエージェントのオーケストレーション能力が大幅に向上しています。これらのモデルは、専門サブエージェントに作業を委任すると有益なタスクを認識し、明示的な指示がなくても自発的に委任できます。

このふるまいを活用するには:

1. 定義の明確なサブエージェントツールを用意する: サブエージェントツールをツール定義として用意し、説明を記載しておきます
2. Claude に自然なオーケストレーションを任せる: 明示的な指示がなくても、Claude は適切に委任します
3. 必要に応じて保守性を調整する:

```text Sample prompt for conservative subagent usage
Only delegate to subagents when the task clearly benefits from a separate agent with a new context window.
```

### モデルの自己認識

アプリケーション内で Claude に正しく自己同定させたい、または特定の API 文字列を使いたい場合:

```text Sample prompt for model identity
The assistant is Claude, created by Anthropic. The current model is Claude Sonnet 4.5.
```

モデル文字列を指定する必要がある LLM 駆動アプリ向け:

```text Sample prompt for model string
When an LLM is needed, please default to Claude Sonnet 4.5 unless the user requests otherwise. The exact model string for Claude Sonnet 4.5 is claude-sonnet-4-5-20250929.
```

### 「think」への感度

拡張思考が無効な場合、Claude Opus 4.5 は "think" およびその派生語に特に敏感です。"think" の代わりに "consider"、"believe"、"evaluate" など、同様の意味を伝える語に置き換えることを推奨します。

### 思考とインターリーブ思考能力を活用する

Claude 4.x モデルは、ツール使用後の省察や複雑な多段推論を伴うタスクで特に役立つ思考能力を提供します。初期の思考やインターリーブ思考を誘導することで、より良い結果が得られます。

```text Example prompt
After receiving tool results, carefully reflect on their quality and determine optimal next steps before proceeding. Use your thinking to plan and iterate based on this new information, and then take the best next action.
```

> 情報:
> 思考能力の詳細は[Extended thinking](/docs/en/build-with-claude/extended-thinking)を参照してください。

### ドキュメント作成

Claude 4.5 モデルは、プレゼンテーション、アニメーション、ビジュアルドキュメントの作成に優れています。これらのモデルは、この領域で Claude Opus 4.1 に匹敵またはそれ以上の性能を示し、創造的なセンスとより強力な指示追従を備えています。多くの場合、初回から洗練された実用的な出力を生成します。

ドキュメント作成で最良の結果を得るには:

```text Sample prompt
Create a professional presentation on [topic]. Include thoughtful design elements, visual hierarchy, and engaging animations where appropriate.
```

### ビジョン機能の向上

Claude Opus 4.5 は、従来の Claude モデルと比較してビジョン機能が改善されています。画像処理やデータ抽出タスクで、特に複数の画像がコンテキストに存在する場合に性能が向上しています。この改善はコンピュータ操作にも及び、スクリーンショットや UI 要素をより確実に解釈できます。動画をフレームに分割して分析することも可能です。

さらに性能を高める有効な手法として、Claude Opus 4.5 にクロップツールや[スキル](/docs/en/agents-and-tools/agent-skills/overview)を与える方法があります。画像内の関連領域に「ズーム」できると、画像評価で一貫した向上が見られます。クロップツールのクックブックは[こちら](https://platform.claude.com/cookbook/multimodal-crop-tool)にまとめています。

### 並列ツール呼び出しを最適化する

Claude 4.x モデルは並列ツール実行に秀でており、特に Sonnet 4.5 は複数の操作を同時に積極的に実行します。Claude 4.x モデルは次のように動作します:

- 調査中に複数の推測的検索を並行実行
- 文脈構築を早めるために複数ファイルを同時に読む
- bash コマンドを並列実行（システム性能のボトルネックになりうることも）

このふるまいは容易に誘導可能です。プロンプトなしでも並列ツール呼び出しの成功率は高いですが、これをほぼ 100% に引き上げたり、積極性の度合いを調整したりできます:

```text Sample prompt for maximum parallel efficiency
<use_parallel_tool_calls>
If you intend to call multiple tools and there are no dependencies between the tool calls, make all of the independent tool calls in parallel. Prioritize calling tools simultaneously whenever the actions can be done in parallel rather than sequentially. For example, when reading 3 files, run 3 tool calls in parallel to read all 3 files into context at the same time. Maximize use of parallel tool calls where possible to increase speed and efficiency. However, if some tool calls depend on previous calls to inform dependent values like the parameters, do NOT call these tools in parallel and instead call them sequentially. Never use placeholders or guess missing parameters in tool calls.
</use_parallel_tool_calls>
```

```text Sample prompt to reduce parallel execution
Execute operations sequentially with brief pauses between each step to ensure stability.
```

### エージェント型コーディングでのファイル作成を減らす

Claude 4.x モデルは、とりわけコード作業時に、テストや反復のために新しいファイルを作成することがあります。このアプローチにより、特に Python スクリプトを「一時的なスクラッチパッド」として使ってから最終出力を保存できます。とくにエージェント型コーディングのユースケースでは、一時ファイルの使用が成果を改善することがあります。

新規ファイルの作成を最小限に抑えたい場合は、後片付けをするよう指示できます:

```text Sample prompt
If you create any temporary new files, scripts, or helper files for iteration, clean up these files by removing them at the end of the task.
```

### 過剰な意欲とファイル作成

Claude Opus 4.5 は、追加ファイルの作成、不要な抽象化の導入、要求されていない柔軟性の付与など、過剰設計に走る傾向があります。この望ましくないふるまいが見られる場合は、解決策を最小限に保つよう明示的にプロンプトで促してください。

例えば:

```text Sample prompt to minimize overengineering
Avoid over-engineering. Only make changes that are directly requested or clearly necessary. Keep solutions simple and focused.

Don't add features, refactor code, or make "improvements" beyond what was asked. A bug fix doesn't need surrounding code cleaned up. A simple feature doesn't need extra configurability.

Don't add error handling, fallbacks, or validation for scenarios that can't happen. Trust internal code and framework guarantees. Only validate at system boundaries (user input, external APIs). Don't use backwards-compatibility shims when you can just change the code.

Don't create helpers, utilities, or abstractions for one-time operations. Don't design for hypothetical future requirements. The right amount of complexity is the minimum needed for the current task. Reuse existing abstractions where possible and follow the DRY principle.
```

### フロントエンドデザイン

Claude 4.x モデル、特に Opus 4.5 は、強力なフロントエンドデザインを備えた複雑で実用的な Web アプリケーションの構築に優れています。しかし、ガイダンスがないと、ユーザーが「AI slop」と呼ぶ画一的な見た目に陥りがちです。驚きと喜びをもたらす独創的でクリエイティブなフロントエンドを作るには:

> ヒント:
> フロントエンドデザインを改善するための詳細なガイドは、[スキルを通じたフロントエンドデザインの改善](https://www.claude.com/blog/improving-frontend-design-through-skills)に関するブログ記事をご覧ください。

より良いフロントエンドデザインを促すために使えるシステムプロンプトのスニペットを以下に示します:

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

完全なスキルは[こちら](https://github.com/anthropics/claude-code/blob/main/plugins/frontend-design/skills/frontend-design/SKILL.md)も参照できます。

### テスト合格やハードコーディングに偏らない

Claude 4.x モデルは、一般的な解法よりもテストに合格することに過度に注力したり、複雑なリファクタリングで標準ツールを直接使う代わりに補助スクリプトのような回避策を用いたりすることがあります。このふるまいを防ぎ、堅牢で汎用的な解決策を確保するには:

```text Sample prompt
Please write a high-quality, general-purpose solution using the standard tools available. Do not create helper scripts or workarounds to accomplish the task more efficiently. Implement a solution that works correctly for all valid inputs, not just the test cases. Do not hard-code values or create solutions that only work for specific test inputs. Instead, implement the actual logic that solves the problem generally.

Focus on understanding the problem requirements and implementing the correct algorithm. Tests are there to verify correctness, not to define the solution. Provide a principled implementation that follows best practices and software design principles.

If the task is unreasonable or infeasible, or if any of the tests are incorrect, please inform me rather than working around them. The solution should be robust, maintainable, and extendable.
```

### コード探索を促す

Claude Opus 4.5 は高い能力を持ちますが、コード探索において過度に慎重になることがあります。コードを読まずに解決策を提案したり、未読のコードについて仮定したりしていると感じた場合は、プロンプトに明確な指示を追加するのが最良です。Claude Opus 4.5 はこれまでで最も誘導しやすいモデルであり、直接的なガイダンスに確実に反応します。

例えば:

```text Sample prompt for code exploration
ALWAYS read and understand relevant files before proposing code edits. Do not speculate about code you have not inspected. If the user references a specific file/path, you MUST open and inspect it before explaining or proposing fixes. Be rigorous and persistent in searching code for key facts. Thoroughly review the style, conventions, and abstractions of the codebase before implementing new features or abstractions.
```

### エージェント型コーディングにおける幻覚の最小化

Claude 4.x モデルは幻覚が起きにくく、コードに基づいたより正確で根拠のある知的な回答を返します。このふるまいをさらに促し、幻覚を最小化するには:

```text Sample prompt
<investigate_before_answering>
Never speculate about code you have not opened. If the user references a specific file, you MUST read the file before answering. Make sure to investigate and read relevant files BEFORE answering questions about the codebase. Never make any claims about code before investigating unless you are certain of the correct answer - give grounded and hallucination-free answers.
</investigate_before_answering>
```

## 移行に関する考慮事項

Claude 4.5 モデルへ移行する際は:

1. 望むふるまいを具体的に示す: 出力で見たい内容を正確に記述することを検討してください。

2. 修飾を付けて指示を表現する: Claude の出力の品質や詳細を高めるため、修飾語を加えて指示を枠付けると性能の調整に役立ちます。例えば「分析ダッシュボードを作成して」ではなく、「分析ダッシュボードを作成してください。関連する機能やインタラクションを可能な限り多く含めてください。基本を超えて、フル機能の実装にしてください。」のようにします。

3. 具体的な機能は明示的に要求する: アニメーションやインタラクティブ要素は、必要な場合に明示的にリクエストしてください。
