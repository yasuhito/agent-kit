出典: https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-4-best-practices.md
スナップショット: 5945216cb8f4dc746276ada5b7fbf2a61b180c3ff32abc0a7c786e5774d52857
最終取得: 2026-01-24T22:05:35Z

# プロンプト作成のベストプラクティス

---

このガイドでは、Claude 4.x モデル向けの具体的なプロンプトエンジニアリング手法を、Sonnet 4.5、Haiku 4.5、Opus 4.5 に関する具体的な指針とともに紹介します。これらのモデルは、従来の Claude モデルよりも精密な指示追従ができるように訓練されています。
> **ヒント:**
> Claude 4.5 の新機能の概要は [What's new in Claude 4.5](/docs/en/about-claude/models/whats-new-claude-4-5) を参照してください。以前のモデルからの移行ガイダンスは [Migrating to Claude 4.5](/docs/en/about-claude/models/migrating-to-claude-4) を参照してください。

## 一般原則

### 指示を明確かつ具体的にする

Claude 4.x モデルは、明確で具体的な指示によく反応します。望む出力を具体的に指定することで、結果を高められます。従来の Claude モデルが示した「期待以上」の振る舞いを求める場合は、新しいモデルではその振る舞いを明示的に要求する必要があるかもしれません。

**例: 分析ダッシュボードの作成**

**効果が低い例:**
```text
Create an analytics dashboard
```

**効果が高い例:**
```text
Create an analytics dashboard. Include as many relevant features and interactions as possible. Go beyond the basics to create a fully-featured implementation.
```

### 文脈を加えて性能を高める

指示の背景や動機（なぜその行動が重要なのかを Claude に説明するなど）を与えることで、Claude 4.x モデルがあなたの目標をよりよく理解し、より的を絞った応答を返せるようになります。

**例: 書式設定の好み**

**効果が低い例:**
```text
NEVER use ellipses
```

**効果が高い例:**
```text
Your response will be read aloud by a text-to-speech engine, so never use ellipses since the text-to-speech engine will not know how to pronounce them.
```

Claude は、その説明から十分に一般化できます。

### 例と詳細に細心の注意を払う

Claude 4.x モデルは、精密な指示追従能力の一環として、例や詳細に細心の注意を払います。望ましい行動を促し、避けたい行動を最小限にするために、例の整合性を確保してください。

### 長期的推論と状態追跡

Claude 4.5 モデルは、卓越した状態追跡能力を備えた長期的推論タスクで優れています。すべてを一度に試みるのではなく、少数のことに着実に取り組むことで、拡張セッション全体での見通しを保ち、漸進的に進捗します。この能力は、とくに複数のコンテキストウィンドウやタスクのイテレーションにおいて発揮され、Claude は複雑なタスクに取り組み、状態を保存し、新しいコンテキストウィンドウで続行できます。

#### コンテキスト認識とマルチウィンドウのワークフロー

Claude 4.5 モデルは [コンテキスト認識](/docs/en/build-with-claude/context-windows#context-awareness-in-claude-sonnet-4-5) を備えており、会話全体を通して残りのコンテキストウィンドウ（つまり「トークン予算」）を追跡できます。これにより、Claude は自分が使えるスペースを理解しつつ、タスクを実行し、コンテキストをより効果的に管理できます。

**コンテキスト上限の管理:**

コンテキストを圧縮したり、外部ファイルにコンテキストを保存できる（Claude Code のような）エージェントのハーネスで Claude を使っている場合は、その情報をプロンプトに追加して、Claude がそれに応じて振る舞えるようにすることを推奨します。そうでないと、コンテキスト上限に近づくにつれて、Claude が自然に作業をまとめようとすることがあります。以下はプロンプトの例です:

```text Sample prompt
Your context window will be automatically compacted as it approaches its limit, allowing you to continue working indefinitely from where you left off. Therefore, do not stop tasks early due to token budget concerns. As you approach your token budget limit, save your current progress and state to memory before the context window refreshes. Always be as persistent and autonomous as possible and complete tasks fully, even if the end of your budget is approaching. Never artificially stop any task early regardless of the context remaining.
```

[メモリツール](/docs/en/agents-and-tools/tool-use/memory-tool) は、コンテキスト認識と自然に組み合わさり、シームレスなコンテキスト移行を実現します。

#### 複数コンテキストウィンドウのワークフロー

複数のコンテキストウィンドウにまたがるタスクでは:

1. **最初のコンテキストウィンドウには異なるプロンプトを使う**: 最初のコンテキストウィンドウではフレームワーク（テストの作成、セットアップスクリプトの作成）を整え、その後のコンテキストウィンドウで TODO リストに沿ってイテレーションします。

2. **構造化形式でテストを書かせる**: 作業を始める前に Claude にテストを作成させ、それらを（例: `tests.json` のような）構造化形式で管理します。これにより長期的なイテレーション能力が向上します。テストの重要性をリマインドしてください: 「テストを削除したり編集するのは許容できません。そうすると機能の欠落やバグにつながる可能性があります。」

3. **作業効率向上ツールのセットアップ**: サーバー起動、テストスイートやリンターの実行を円滑にするセットアップスクリプト（例: `init.sh`）の作成を促します。新しいコンテキストウィンドウから再開するときの繰り返し作業を防げます。

4. **ゼロから始めるか圧縮するか**: コンテキストウィンドウがクリアされたとき、コンテキストを圧縮するのではなく、まっさらなコンテキストウィンドウから始めることを検討してください。Claude 4.5 モデルはローカルファイルシステムから状態を発見する能力に非常に長けています。場合によっては、圧縮よりもこの利点を活かしたいことがあります。開始方法については指示を明確にしてください:
   - 「pwd を実行してください。このディレクトリ内のファイルしか読み書きできません。」
   - 「progress.txt、tests.json、git のログを確認してください。」
   - 「新機能の実装に進む前に、基本的な統合テストを手動で一通り実施してください。」

5. **検証ツールを提供する**: 自律タスクの長さが増すにつれ、人間のフィードバックなしに正しさを検証する必要が出てきます。UI のテスト用に Playwright MCP サーバーやコンピュータ操作機能などのツールが役立ちます。

6. **コンテキストを使い切るよう促す**: 先に進む前に、コンポーネントを効率的に完了するよう Claude に促してください:

```text Sample prompt
This is a very long task, so it may be beneficial to plan out your work clearly. It's encouraged to spend your entire output context working on the task - just make sure you don't run out of context with significant uncommitted work. Continue working systematically until you have completed this task.
```

#### 状態管理のベストプラクティス

- **状態データには構造化形式を使う**: 構造化情報（テスト結果やタスク状況など）を追跡する場合は、JSON などの構造化形式を使って、Claude がスキーマ要件を理解しやすくしてください
- **進捗メモには非構造化テキストを使う**: 自由形式の進捗メモは、全般的な進行状況やコンテキストの追跡に有効です
- **状態追跡に git を使う**: git は実施内容のログと、復元可能なチェックポイントを提供します。Claude 4.5 モデルは、複数セッションにわたる状態追跡に git を使う際、とくに高い性能を発揮します。
- **漸進的な進捗を強調する**: 進捗を記録し、漸進的な作業に集中するように明示的に依頼してください

**例: 状態追跡**

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

Claude 4.5 モデルは、従来モデルと比べて、より簡潔で自然なコミュニケーションスタイルを持っています:

- **より直接的で地に足のついた表現**: 自賛的な更新ではなく、事実に基づく進捗報告を提供します
- **より会話的**: わずかに流暢で口語的であり、機械的でない
- **より簡潔**: 指示がない限り、効率性のために詳細な要約を省くことがあります

このコミュニケーションスタイルは、不要な冗長さなく、達成されたことを正確に反映します。

## 特定の状況におけるガイダンス

### 冗長さのバランスを取る

Claude 4.5 モデルは効率性を重視する傾向があり、ツール呼び出し後の口頭での要約を省略して、次のアクションに直接移ることがあります。これはワークフローを合理化しますが、その思考過程の可視性を高めたい場合もあるでしょう。

作業中に Claude から更新を提供させたい場合は:

```text Sample prompt
After completing a task that involves tool use, provide a quick summary of the work you've done.
```

### ツール使用パターン

Claude 4.5 モデルは精密な指示追従のために訓練されており、特定のツールを使う明示的な指示から恩恵を受けます。「いくつか変更案を提案して」と言うと、たとえあなたの意図が実装であっても、提案だけを返すことがあります。

Claude に行動させるには、より明示的に:

**例: 明示的な指示**

**効果が低い（Claude は提案のみ行う）:**
```text
Can you suggest some changes to improve this function?
```

**効果が高い（Claude が変更を実行する）:**
```text
Change this function to improve its performance.
```

または:
```text
Make these edits to the authentication flow.
```

デフォルトで Claude をより能動的にして行動するようにしたい場合は、システムプロンプトに以下を追加できます:

```text Sample prompt for proactive action
<default_to_action>
By default, implement changes rather than only suggesting them. If the user's intent is unclear, infer the most useful likely action and proceed, using tools to discover any missing details instead of guessing. Try to infer the user's intent about whether a tool call (e.g., file edit or read) is intended or not, and act accordingly.
</default_to_action>
```

一方で、モデルをデフォルトでより慎重にし、すぐに実装へ飛びつかず、依頼された場合のみ行動するようにしたい場合は、次のようなプロンプトでこの振る舞いを誘導できます:

```text Sample prompt for conservative action
<do_not_act_before_instructions>
Do not jump into implementatation or changes files unless clearly instructed to make changes. When the user's intent is ambiguous, default to providing information, doing research, and providing recommendations rather than taking action. Only proceed with edits, modifications, or implementations when the user explicitly requests them.
</do_not_act_before_instructions>
```

### ツール使用とトリガー

Claude Opus 4.5 は、従来モデルよりもシステムプロンプトに敏感です。ツールやスキルの過少トリガーを減らすために設計したプロンプトがある場合、Claude Opus 4.5 では過剰トリガーが発生することがあります。対策は、攻撃的な言い回しを抑えることです。以前は「重要: このツールは必ず使え…」と言っていたところを、「このツールは…の場合に使ってください」といった通常のプロンプトに切り替えてください。

### 応答形式を制御する

Claude 4.x モデルで出力形式を誘導するのに、特に効果的だとわかっている方法がいくつかあります:

1. **してほしくないことではなく、してほしいことを伝える**

   - 次のように言う代わりに: 「応答で markdown を使わないでください」
   - 試す: 「応答は滑らかに流れる散文の段落で構成してください。」

2. **XML 形式のインジケータを使う**

   - 試す: 「応答の散文部分は <smoothly_flowing_prose_paragraphs> タグで記述してください。」

3. **プロンプトのスタイルを望む出力に合わせる**

   プロンプトで用いる書式スタイルは、Claude の応答スタイルに影響することがあります。出力形式の誘導に引き続き問題がある場合は、可能な限り、望む出力スタイルにプロンプトスタイルを合わせることを推奨します。例えば、プロンプトから markdown を取り除くと、出力中の markdown の量を減らせます。

4. **特定の書式の好みには詳細なプロンプトを使う**

   markdown や書式の使用をより細かく制御するには、明示的なガイダンスを提供してください:

```text Sample prompt to minimize markdown
<avoid_excessive_markdown_and_bullet_points>
When writing reports, documents, technical explanations, analyses, or any long-form content, write in clear, flowing prose using complete paragraphs and sentences. Use standard paragraph breaks for organization and reserve markdown primarily for `inline code`, code blocks (```...```), and simple headings (###, and ###). Avoid using **bold** and *italics*.

DO NOT use ordered lists (1. ...) or unordered lists (*) unless : a) you're presenting truly discrete items where a list format is the best option, or b) the user explicitly requests a list or ranking

Instead of listing items with bullets or numbers, incorporate them naturally into sentences. This guidance applies especially to technical writing. Using prose instead of excessive formatting will improve user satisfaction. NEVER output a series of overly short bullet points.

Your goal is readable, flowing text that guides the reader naturally through ideas rather than fragmenting information into isolated points.
</avoid_excessive_markdown_and_bullet_points>
```

### 調査と情報収集

Claude 4.5 モデルは卓越したエージェント的検索能力を示し、複数の情報源から効果的に情報を発見・統合できます。最適な調査結果のために:

1. **明確な成功基準を提供する**: 調査質問に対する「成功」とは何かを定義する

2. **情報源の検証を促す**: 複数の情報源で情報を検証するよう Claude に依頼する

3. **複雑な調査タスクには構造化アプローチを使う**:

```text Sample prompt for complex research
Search for this information in a structured way. As you gather data, develop several competing hypotheses. Track your confidence levels in your progress notes to improve calibration. Regularly self-critique your approach and plan. Update a hypothesis tree or research notes file to persist information and provide transparency. Break down this complex research task systematically.
```

この構造化アプローチにより、Claude は実質的にあらゆる情報を発見・統合し、その発見を反復的に批判的検討できます。コーパスの規模にかかわらず有効です。

### サブエージェントのオーケストレーション

Claude 4.5 モデルは、ネイティブなサブエージェントのオーケストレーション能力が大幅に向上しています。これらのモデルは、タスクが専門のサブエージェントに委譲した方が有利な場合を認識し、明示的な指示がなくても能動的に委譲します。

この挙動を活用するには:

1. **サブエージェント用ツールを明確に定義する**: サブエージェントのツールが利用可能で、ツール定義に記述されていること
2. **Claude に自然なオーケストレーションを任せる**: 明示的な指示がなくても、Claude は適切に委譲します
3. **必要に応じて慎重さを調整する**:

```text Sample prompt for conservative subagent usage
Only delegate to subagents when the task clearly benefits from a separate agent with a new context window.
```

### モデルの自己認識

アプリケーションで Claude に正しく自己同定させたい場合や、特定の API 文字列を使いたい場合は:

```text Sample prompt for model identity
The assistant is Claude, created by Anthropic. The current model is Claude Sonnet 4.5.
```

LLM 駆動のアプリでモデル文字列を指定する必要がある場合:

```text Sample prompt for model string
When an LLM is needed, please default to Claude Sonnet 4.5 unless the user requests otherwise. The exact model string for Claude Sonnet 4.5 is claude-sonnet-4-5-20250929.
```

### 「思考」への感度

拡張思考が無効な場合、Claude Opus 4.5 は「think」という語やその派生語に特に敏感です。「think」の代わりに「consider（考慮する）」「believe（考える）」「evaluate（評価する）」など、同様の意味を伝える別の語に置き換えることを推奨します。

### 思考およびインタリーブ思考機能を活用する

Claude 4.x モデルは、ツール使用後の内省や複雑な多段推論を伴うタスクに特に役立つ思考機能を提供します。初期の思考や介在（インタリーブ）思考を誘導することで、より良い結果を得られます。

```text Example prompt
After receiving tool results, carefully reflect on their quality and determine optimal next steps before proceeding. Use your thinking to plan and iterate based on this new information, and then take the best next action.
```

> **情報:**
> 思考機能の詳細は [Extended thinking](/docs/en/build-with-claude/extended-thinking) を参照してください。

### ドキュメント作成

Claude 4.5 モデルは、プレゼンテーション、アニメーション、ビジュアルドキュメントの作成に優れています。これらのモデルは、この領域で Claude Opus 4.1 に匹敵するか上回り、印象的な創造性とより強固な指示追従を備えています。多くのケースで、最初の試行から磨き上げられた実用的な出力を生成します。

ドキュメント作成で最高の結果を得るには:

```text Sample prompt
Create a professional presentation on [topic]. Include thoughtful design elements, visual hierarchy, and engaging animations where appropriate.
```

### ビジョン機能の向上

Claude Opus 4.5 は、従来の Claude モデルと比べてビジョン機能が向上しています。とくに複数の画像がコンテキストにある場合、画像処理やデータ抽出タスクでより良い性能を発揮します。これらの改善はコンピュータ操作にも波及し、スクリーンショットや UI 要素をより確実に解釈できます。また、Claude Opus 4.5 を使って動画をフレームに分割して分析することも可能です。

性能をさらに高めるために効果的だとわかった手法の一つは、Claude Opus 4.5 にクロップツールや[スキル](/docs/en/agents-and-tools/agent-skills/overview)を与えることです。Claude が画像の関連領域に「ズームイン」できると、画像評価で一貫した向上が見られます。クロップツールのクックブックを[こちら](https://platform.claude.com/cookbook/multimodal-crop-tool)に用意しています。

### 並列ツール呼び出しの最適化

Claude 4.x モデルは並列ツール実行に優れており、特に Sonnet 4.5 は複数の操作を積極的に同時発火します。Claude 4.x モデルは以下を行います:

- 調査中に複数の試行的検索を実行する
- コンテキストを早く構築するために複数のファイルを同時に読む
- bash コマンドを並列実行する（システム性能がボトルネックになることすらあります）

この挙動は容易に制御できます。プロンプトなしでもモデルは高い成功率で並列ツール呼び出しを行いますが、これをほぼ 100% に引き上げたり、積極性のレベルを調整したりできます:

```text Sample prompt for maximum parallel efficiency
<use_parallel_tool_calls>
If you intend to call multiple tools and there are no dependencies between the tool calls, make all of the independent tool calls in parallel. Prioritize calling tools simultaneously whenever the actions can be done in parallel rather than sequentially. For example, when reading 3 files, run 3 tool calls in parallel to read all 3 files into context at the same time. Maximize use of parallel tool calls where possible to increase speed and efficiency. However, if some tool calls depend on previous calls to inform dependent values like the parameters, do NOT call these tools in parallel and instead call them sequentially. Never use placeholders or guess missing parameters in tool calls.
</use_parallel_tool_calls>
```

```text Sample prompt to reduce parallel execution
Execute operations sequentially with brief pauses between each step to ensure stability.
```

### エージェント駆動のコーディングでのファイル作成を減らす

Claude 4.x モデルは、とくにコード作業の際、テストやイテレーションのために新しいファイルを作成することがあります。このアプローチにより、Claude は（とくに Python スクリプトなどの）ファイルを最終出力を保存する前の「一時的な作業用スクラッチパッド」として使えます。とくにエージェント駆動のコーディング用途では、一時ファイルの使用が成果を改善することがあります。

新規ファイルの純増を最小限にしたい場合は、後片付けを指示できます:

```text Sample prompt
If you create any temporary new files, scripts, or helper files for iteration, clean up these files by removing them at the end of the task.
```

### 過剰な作り込みとファイル作成

Claude Opus 4.5 は、追加のファイルを作成したり、不要な抽象化を加えたり、要求されていない柔軟性を組み込んだりして、過剰設計になりがちです。望ましくないこの挙動が見られる場合は、ソリューションを最小限に保つよう明示的にプロンプトで促してください。

例えば:

```text Sample prompt to minimize overengineering
Avoid over-engineering. Only make changes that are directly requested or clearly necessary. Keep solutions simple and focused.

Don't add features, refactor code, or make "improvements" beyond what was asked. A bug fix doesn't need surrounding code cleaned up. A simple feature doesn't need extra configurability.

Don't add error handling, fallbacks, or validation for scenarios that can't happen. Trust internal code and framework guarantees. Only validate at system boundaries (user input, external APIs). Don't use backwards-compatibility shims when you can just change the code.

Don't create helpers, utilities, or abstractions for one-time operations. Don't design for hypothetical future requirements. The right amount of complexity is the minimum needed for the current task. Reuse existing abstractions where possible and follow the DRY principle.
```

### フロントエンドデザイン

Claude 4.x モデル、特に Opus 4.5 は、フロントエンドデザインに優れた複雑で実用的な Web アプリケーションの構築に秀でています。ただし、指針がないと、一般的なパターンに流れて、ユーザーが「AI スロップ」と呼ぶ美観に陥ることがあります。驚きと喜びをもたらす独創的でクリエイティブなフロントエンドを作るには:

> **ヒント:**
> フロントエンドデザイン改善の詳細ガイドは、[スキルを通じたフロントエンドデザイン改善](https://www.claude.com/blog/improving-frontend-design-through-skills) に関するブログ記事をご覧ください。

より優れたフロントエンドデザインを促すために使えるシステムプロンプトのスニペットを以下に示します:

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

### テスト合格への偏重やハードコーディングを避ける

Claude 4.x モデルは、ときにより一般的な解法を犠牲にしてテスト合格に注力しすぎたり、複雑なリファクタリングのために標準ツールを直接使う代わりにヘルパースクリプトなどの回避策を使うことがあります。この挙動を防ぎ、堅牢で一般化可能な解法を確保するには:

```text Sample prompt
Please write a high-quality, general-purpose solution using the standard tools available. Do not create helper scripts or workarounds to accomplish the task more efficiently. Implement a solution that works correctly for all valid inputs, not just the test cases. Do not hard-code values or create solutions that only work for specific test inputs. Instead, implement the actual logic that solves the problem generally.

Focus on understanding the problem requirements and implementing the correct algorithm. Tests are there to verify correctness, not to define the solution. Provide a principled implementation that follows best practices and software design principles.

If the task is unreasonable or infeasible, or if any of the tests are incorrect, please inform me rather than working around them. The solution should be robust, maintainable, and extendable.
```

### コード探索を促す

Claude Opus 4.5 は非常に有能ですが、コード探索において慎重すぎることがあります。コードを見ずに解法を提案したり、読んでいないコードについて仮定を置いたりする兆候が見られる場合は、プロンプトに明示的な指示を追加するのが最善策です。Claude Opus 4.5 はこれまでで最も誘導しやすいモデルであり、直接のガイダンスに確実に反応します。

例えば:

```text Sample prompt for code exploration
ALWAYS read and understand relevant files before proposing code edits. Do not speculate about code you have not inspected. If the user references a specific file/path, you MUST open and inspect it before explaining or proposing fixes. Be rigorous and persistent in searching code for key facts. Thoroughly review the style, conventions, and abstractions of the codebase before implementing new features or abstractions.
```

### エージェント駆動のコーディングでのハルシネーション最小化

Claude 4.x モデルはハルシネーションに陥りにくく、コードに基づいたより正確で根拠ある賢明な回答を返します。この挙動をさらに促し、ハルシネーションを最小化するには:

```text Sample prompt
<investigate_before_answering>
Never speculate about code you have not opened. If the user references a specific file, you MUST read the file before answering. Make sure to investigate and read relevant files BEFORE answering questions about the codebase. Never make any claims about code before investigating unless you are certain of the correct answer - give grounded and hallucination-free answers.
</investigate_before_answering>
```

## 移行に関する考慮事項

Claude 4.5 モデルへ移行する際は:

1. **望む挙動を具体的に示す**: 出力で見たい内容を正確に記述することを検討してください。

2. **修飾を用いて指示を枠付けする**: Claude に出力の質と詳細を高めるよう促す修飾を加えると、性能をより良く形作れます。例えば「分析ダッシュボードを作成して」ではなく、「分析ダッシュボードを作成してください。関連する機能やインタラクションを可能な限り多く含めてください。基本を超えて、フル機能の実装にしてください。」のようにします。

3. **特定の機能を明示的に依頼する**: アニメーションやインタラクティブ要素は、必要であれば明示的に依頼してください。
