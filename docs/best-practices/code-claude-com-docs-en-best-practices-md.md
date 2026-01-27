出典: https://code.claude.com/docs/en/best-practices.md
スナップショット: 48965cf2ee49f219ed211e5260cfc74c50226648e752116ae90a77ca6b95610c
最終取得: 2026-01-25T03:48:52Z

> ## ドキュメント索引
> 完全なドキュメント索引は次で取得してください: https://code.claude.com/docs/llms.txt
> 先に進む前に、このファイルで利用可能なすべてのページを確認してください。

# Claude Code のベストプラクティス

> 環境の設定から並列セッションへのスケーリングまで、Claude Code を最大限に活用するためのヒントとパターン。

Claude Code はエージェント的なコーディング環境です。質問に答えて待つチャットボットとは異なり、Claude Code はファイルを読み、コマンドを実行し、変更を加え、あなたが見守ったり方向転換したり完全に離れている間も自律的に問題に取り組めます。

これはあなたの働き方を変えます。自分でコードを書いて Claude にレビューしてもらうのではなく、やりたいことを説明すると Claude が実装方法を見つけます。Claude は探索し、計画し、実装します。

ただし、この自律性にも学習曲線があります。Claude は理解しておくべき特定の制約の中で動作します。

このガイドは、Anthropic の社内チームや、さまざまなコードベース・言語・環境で Claude Code を使うエンジニアにおいて有効だと実証されたパターンを扱います。エージェント的ループの仕組みについては、[How Claude Code works](/en/how-claude-code-works) を参照してください。

***

多くのベストプラクティスは 1 つの制約に基づいています: Claude のコンテキストウィンドウはすぐに埋まり、埋まるほど性能が低下するということです。

Claude のコンテキストウィンドウには、やり取り全体が入ります。すべてのメッセージ、Claude が読んだすべてのファイル、すべてのコマンド出力が含まれます。しかし、これはすぐに埋まります。1 回のデバッグやコードベース探索だけでも、数万トークンを生成・消費することがあります。

これは重要です。コンテキストが埋まるにつれて LLM の性能は低下するからです。コンテキストウィンドウが満杯に近づくと、Claude は以前の指示を「忘れ」たり、ミスが増えたりする可能性があります。コンテキストウィンドウは最も重要なリソースです。トークン使用量を減らすための詳細な戦略については、[Reduce token usage](/en/costs#reduce-token-usage) を参照してください。

***

## Claude に自分の作業を検証する手段を与える

> **ヒント:**
> テスト、スクリーンショット、期待される出力などを含め、Claude が自分でチェックできるようにしましょう。これは最もレバレッジの高い取り組みです。

Claude は、自分の作業を検証できる場合、たとえばテストを実行し、スクリーンショットを比較し、出力を検証できる場合に劇的に性能が向上します。

明確な成功基準がなければ、見た目は正しそうでも実際には動かないものを出してしまうかもしれません。あなたが唯一のフィードバックループとなり、毎回のミスに対応が必要になります。

| 戦略                                  | 前                                                      | 後                                                                                                                                                                                                        |
| ------------------------------------- | ------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **検証基準を提供する**                | 「メールアドレスを検証する関数を実装して」              | 「validateEmail 関数を書いてください。例のテストケース: [user@example.com](mailto:user@example.com) は true、invalid は false、[user@.com](mailto:user@.com) は false。実装後にテストを実行」         |
| **UI 変更を視覚的に検証する**         | 「ダッシュボードの見た目を良くして」                    | 「[スクリーンショットを貼り付け] このデザインを実装してください。結果のスクリーンショットを撮り、元のものと比較。差分を列挙して修正」                                                                  |
| **症状ではなく根本原因に対処する**    | 「ビルドが失敗している」                                | 「ビルドは次のエラーで失敗します: [エラーを貼り付け]。修正してビルドが成功することを検証。根本原因に対処し、エラーを抑制しないこと」                                                                  |

UI の変更は [Claude in Chrome extension](/en/chrome) を使って検証できます。ブラウザを開き、UI をテストし、コードが動作するまで反復します。

検証手段はテストスイート、リンター、出力をチェックする Bash コマンドでも構いません。検証を堅牢にすることに投資しましょう。

***

## まず探索、次に計画、そしてコーディング

> **ヒント:**
> 調査と計画を実装から切り離し、間違った問題を解かないようにしましょう。

Claude にいきなりコーディングさせると、間違った問題を解くコードが生成されることがあります。[Plan Mode](/en/common-workflows#use-plan-mode-for-safe-code-analysis) を使って、探索と実行を分離しましょう。

推奨ワークフローは 4 段階です:

<Steps>
  <Step title="探索">
    Plan Mode に入ります。Claude は変更を加えずにファイルを読み、質問に答えます。

    ```txt claude (Plan Mode) theme={null}
    read /src/auth and understand how we handle sessions and login.
    also look at how we manage environment variables for secrets.
    ```
  </Step>

  <Step title="Plan">
    Ask Claude to create a detailed implementation plan.

    ```txt claude (Plan Mode) theme={null}
    I want to add Google OAuth. What files need to change?
    What's the session flow? Create a plan.
    ```
  </Step>

  <Step title="Implement">
    Switch back to Normal Mode and let Claude code, verifying against its plan.

    ```txt claude (Normal Mode) theme={null}
    implement the OAuth flow from your plan. write tests for the
    callback handler, run the test suite and fix any failures.
    ```
  </Step>

  <Step title="Commit">
    Ask Claude to commit with a descriptive message and create a PR.

    ```txt claude (Normal Mode) theme={null}
    commit with a descriptive message and open a PR
    ```
  </Step>
</Steps>

<Callout>
  Plan Mode is useful, but also adds overhead.

  For tasks where the scope is clear and the fix is small (like fixing a typo, adding a log line, or renaming a variable) ask Claude to do it directly.

  Planning is most useful when you're uncertain about the approach, when the change modifies multiple files, or when you're unfamiliar with the code being modified. If you could describe the diff in one sentence, skip the plan.
</Callout>

***

## Provide specific context in your prompts

> **Tip:**
> The more precise your instructions, the fewer corrections you'll need.

Claude can infer intent, but it can't read your mind. Reference specific files, mention constraints, and point to example patterns.

| Strategy                                                                                         | Before                                               | After                                                                                                                                                                                                                                                                                                                                                            |
| ------------------------------------------------------------------------------------------------ | ---------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Scope the task.** Specify which file, what scenario, and testing preferences.                  | *"add tests for foo.py"*                             | *"write a test for foo.py covering the edge case where the user is logged out. avoid mocks."*                                                                                                                                                                                                                                                                    |
| **Point to sources.** Direct Claude to the source that can answer a question.                    | *"why does ExecutionFactory have such a weird api?"* | *"look through ExecutionFactory's git history and summarize how its api came to be"*                                                                                                                                                                                                                                                                             |
| **Reference existing patterns.** Point Claude to patterns in your codebase.                      | *"add a calendar widget"*                            | *"look at how existing widgets are implemented on the home page to understand the patterns. HotDogWidget.php is a good example. follow the pattern to implement a new calendar widget that lets the user select a month and paginate forwards/backwards to pick a year. build from scratch without libraries other than the ones already used in the codebase."* |
| **Describe the symptom.** Provide the symptom, the likely location, and what "fixed" looks like. | *"fix the login bug"*                                | *"users report that login fails after session timeout. check the auth flow in src/auth/, especially token refresh. write a failing test that reproduces the issue, then fix it"*                                                                                                                                                                                 |

Vague prompts can be useful when you're exploring and can afford to course-correct. A prompt like `"このファイルで改善すべき点は？"` can surface things you wouldn't have thought to ask about.

### Provide rich content

> **Tip:**
> Use `@` to reference files, paste screenshots/images, or pipe data directly.

You can provide rich data to Claude in several ways:

* **Reference files with `@`** instead of describing where code lives. Claude reads the file before responding.
* **Paste images directly**. Copy/paste or drag and drop images into the prompt.
* **Give URLs** for documentation and API references. Use `/permissions` to allowlist frequently-used domains.
* **Pipe in data** by running `cat error.log | claude` to send file contents directly.
* **Let Claude fetch what it needs**. Tell Claude to pull context itself using Bash commands, MCP tools, or by reading files.

***

## Configure your environment

A few setup steps make Claude Code significantly more effective across all your sessions. For a full overview of extension features and when to use each one, see [Extend Claude Code](/en/features-overview).

### Write an effective CLAUDE.md

> **Tip:**
> Run `/init` to generate a starter CLAUDE.md file based on your current project structure, then refine over time.

CLAUDE.md is a special file that Claude reads at the start of every conversation. Include Bash commands, code style, and workflow rules. This gives Claude persistent context **it can't infer from code alone**.

The `/init` command analyzes your codebase to detect build systems, test frameworks, and code patterns, giving you a solid foundation to refine.

There's no required format for CLAUDE.md files, but keep it short and human-readable. For example:

@@CODE_BLOCK_1@@

CLAUDE.md is loaded every session, so only include things that apply broadly. For domain knowledge or workflows that are only relevant sometimes, use [skills](/en/skills) instead. Claude loads them on demand without bloating every conversation.

Keep it concise. For each line, ask: *"Would removing this cause Claude to make mistakes?"* If not, cut it. Bloated CLAUDE.md files cause Claude to ignore your actual instructions!

| ✅ Include                                            | ❌ Exclude                                          |
| ---------------------------------------------------- | -------------------------------------------------- |
| Bash commands Claude can't guess                     | Anything Claude can figure out by reading code     |
| Code style rules that differ from defaults           | Standard language conventions Claude already knows |
| Testing instructions and preferred test runners      | Detailed API documentation (link to docs instead)  |
| Repository etiquette (branch naming, PR conventions) | Information that changes frequently                |
| Architectural decisions specific to your project     | Long explanations or tutorials                     |
| Developer environment quirks (required env vars)     | File-by-file descriptions of the codebase          |
| Common gotchas or non-obvious behaviors              | Self-evident practices like "write clean code"     |

If Claude keeps doing something you don't want despite having a rule against it, the file is probably too long and the rule is getting lost. If Claude asks you questions that are answered in CLAUDE.md, the phrasing might be ambiguous. Treat CLAUDE.md like code: review it when things go wrong, prune it regularly, and test changes by observing whether Claude's behavior actually shifts.

You can tune instructions by adding emphasis (e.g., "IMPORTANT" or "YOU MUST") to improve adherence. Check CLAUDE.md into git so your team can contribute. The file compounds in value over time.

CLAUDE.md files can import additional files using `@path/to/import` syntax:

@@CODE_BLOCK_2@@

You can place CLAUDE.md files in several locations:

* **Home folder (`~/.claude/CLAUDE.md`)**: Applies to all Claude sessions
* **Project root (`./CLAUDE.md`)**: Check into git to share with your team, or name it `CLAUDE.local.md` and `.gitignore` it
* **Parent directories**: Useful for monorepos where both `root/CLAUDE.md` and `root/foo/CLAUDE.md` are pulled in automatically
* **Child directories**: Claude pulls in child CLAUDE.md files on demand when working with files in those directories

### Configure permissions

> **Tip:**
> Use `/permissions` to allowlist safe commands or `/sandbox` for OS-level isolation. This reduces interruptions while keeping you in control.

By default, Claude Code requests permission for actions that might modify your system: file writes, Bash commands, MCP tools, etc. This is safe but tedious. After the tenth approval you're not really reviewing anymore, you're just clicking through. There are two ways to reduce these interruptions:

* **Permission allowlists**: Permit specific tools you know are safe (like `npm run lint` or `git commit`)
* **Sandboxing**: Enable OS-level isolation that restricts filesystem and network access, allowing Claude to work more freely within defined boundaries

Alternatively, use `--dangerously-skip-permissions` to bypass all permission checks for contained workflows like fixing lint errors or generating boilerplate.

> **Warning:**
> Letting Claude run arbitrary commands can result in data loss, system corruption, or data exfiltration via prompt injection. Only use `--dangerously-skip-permissions` in a sandbox without internet access.

Read more about [configuring permissions](/en/settings) and [enabling sandboxing](/en/sandboxing#sandboxing).

### Use CLI tools

> **Tip:**
> Tell Claude Code to use CLI tools like `gh`, `aws`, `gcloud`, and `sentry-cli` when interacting with external services.

CLI tools are the most context-efficient way to interact with external services. If you use GitHub, install the `gh` CLI. Claude knows how to use it for creating issues, opening pull requests, and reading comments. Without `gh`, Claude can still use the GitHub API, but unauthenticated requests often hit rate limits.

Claude is also effective at learning CLI tools it doesn't already know. Try prompts like `「'foo-cli-tool --help' を使って foo ツールについて学び、その後それを使って A, B, C を解決してください。」`

### Connect MCP servers

> **Tip:**
> Run `claude mcp add` to connect external tools like Notion, Figma, or your database.

With [MCP servers](/en/mcp), you can ask Claude to implement features from issue trackers, query databases, analyze monitoring data, integrate designs from Figma, and automate workflows.

### Set up hooks

> **Tip:**
> Use hooks for actions that must happen every time with zero exceptions.

[Hooks](/en/hooks-guide) run scripts automatically at specific points in Claude's workflow. Unlike CLAUDE.md instructions which are advisory, hooks are deterministic and guarantee the action happens.

Claude can write hooks for you. Try prompts like *"Write a hook that runs eslint after every file edit"* or *"Write a hook that blocks writes to the migrations folder."* Run `/hooks` for interactive configuration, or edit `.claude/settings.json` directly.

### Create skills

> **Tip:**
> Create `SKILL.md` files in `.claude/skills/` to give Claude domain knowledge and reusable workflows.

[Skills](/en/skills) extend Claude's knowledge with information specific to your project, team, or domain. Claude applies them automatically when relevant, or you can invoke them directly with `/skill-name`.

Create a skill by adding a directory with a `SKILL.md` to `.claude/skills/`:

@@CODE_BLOCK_3@@

Skills can also define repeatable workflows you invoke directly:

@@CODE_BLOCK_4@@

Run `/fix-issue 1234` to invoke it. Use `disable-model-invocation: true` for workflows with side effects that you want to trigger manually.

### Create custom subagents

> **Tip:**
> Define specialized assistants in `.claude/agents/` that Claude can delegate to for isolated tasks.

[Subagents](/en/sub-agents) run in their own context with their own set of allowed tools. They're useful for tasks that read many files or need specialized focus without cluttering your main conversation.

@@CODE_BLOCK_5@@

Tell Claude to use subagents explicitly: *"Use a subagent to review this code for security issues."*

### Install plugins

> **Tip:**
> Run `/plugin` to browse the marketplace. Plugins add skills, tools, and integrations without configuration.

[Plugins](/en/plugins) bundle skills, hooks, subagents, and MCP servers into a single installable unit from the community and Anthropic. If you work with a typed language, install a [code intelligence plugin](/en/discover-plugins#code-intelligence) to give Claude precise symbol navigation and automatic error detection after edits.

For guidance on choosing between skills, subagents, hooks, and MCP, see [Extend Claude Code](/en/features-overview#match-features-to-your-goal).

***

## Communicate effectively

The way you communicate with Claude Code significantly impacts the quality of results.

### Ask codebase questions

> **Tip:**
> Ask Claude questions you'd ask a senior engineer.

When onboarding to a new codebase, use Claude Code for learning and exploration. You can ask Claude the same sorts of questions you would ask another engineer:

* How does logging work?
* How do I make a new API endpoint?
* What does `async move { ... }` do on line 134 of `foo.rs`?
* What edge cases does `CustomerOnboardingFlowImpl` handle?
* Why does this code call `foo()` instead of `bar()` on line 333?

Using Claude Code this way is an effective onboarding workflow, improving ramp-up time and reducing load on other engineers. No special prompting required: ask questions directly.

### Let Claude interview you

> **Tip:**
> For larger features, have Claude interview you first. Start with a minimal prompt and ask Claude to interview you using the `AskUserQuestion` tool.

Claude asks about things you might not have considered yet, including technical implementation, UI/UX, edge cases, and tradeoffs.

@@CODE_BLOCK_6@@

Once the spec is complete, start a fresh session to execute it. The new session has clean context focused entirely on implementation, and you have a written spec to reference.

***

## Manage your session

Conversations are persistent and reversible. Use this to your advantage!

### Course-correct early and often

> **Tip:**
> Correct Claude as soon as you notice it going off track.

The best results come from tight feedback loops. Though Claude occasionally solves problems perfectly on the first attempt, correcting it quickly generally produces better solutions faster.

* **`Esc`**: Stop Claude mid-action with the `Esc` key. Context is preserved, so you can redirect.
* **`Esc + Esc` or `/rewind`**: Press `Esc` twice or run `/rewind` to open the rewind menu and restore previous conversation and code state.
* **`「それを取り消して」`**: Have Claude revert its changes.
* **`/clear`**: Reset context between unrelated tasks. Long sessions with irrelevant context can reduce performance.

If you've corrected Claude more than twice on the same issue in one session, the context is cluttered with failed approaches. Run `/clear` and start fresh with a more specific prompt that incorporates what you learned. A clean session with a better prompt almost always outperforms a long session with accumulated corrections.

### Manage context aggressively

> **Tip:**
> Run `/clear` between unrelated tasks to reset context.

Claude Code automatically compacts conversation history when you approach context limits, which preserves important code and decisions while freeing space.

During long sessions, Claude's context window can fill with irrelevant conversation, file contents, and commands. This can reduce performance and sometimes distract Claude.

* Use `/clear` frequently between tasks to reset the context window entirely
* When auto compaction triggers, Claude summarizes what matters most, including code patterns, file states, and key decisions
* For more control, run `/compact <instructions>`, like `/compact API の変更に集中してください`
* Customize compaction behavior in CLAUDE.md with instructions like `「コンパクト化する際は、変更されたファイルの完全な一覧と、すべてのテストコマンドを必ず保持すること」` to ensure critical context survives summarization

### Use subagents for investigation

> **Tip:**
> Delegate research with `「X を調査するのにサブエージェントを使って」`. They explore in a separate context, keeping your main conversation clean for implementation.

Since context is your fundamental constraint, subagents are one of the most powerful tools available. When Claude researches a codebase it reads lots of files, all of which consume your context. Subagents run in separate context windows and report back summaries:

@@CODE_BLOCK_7@@

The subagent explores the codebase, reads relevant files, and reports back with findings, all without cluttering your main conversation.

You can also use subagents for verification after Claude implements something:

@@CODE_BLOCK_8@@

### Rewind with checkpoints

> **Tip:**
> Every action Claude makes creates a checkpoint. You can restore conversation, code, or both to any previous checkpoint.

Claude automatically checkpoints before changes. Double-tap `Escape` or run `/rewind` to open the checkpoint menu. You can restore conversation only (keep code changes), restore code only (keep conversation), or restore both.

Instead of carefully planning every move, you can tell Claude to try something risky. If it doesn't work, rewind and try a different approach. Checkpoints persist across sessions, so you can close your terminal and still rewind later.

> **Warning:**
> Checkpoints only track changes made *by Claude*, not external processes. This isn't a replacement for git.

### Resume conversations

> **Tip:**
> Run `claude --continue` to pick up where you left off, or `--resume` to choose from recent sessions.

Claude Code saves conversations locally. When a task spans multiple sessions (you start a feature, get interrupted, come back the next day) you don't have to re-explain the context:

@@CODE_BLOCK_9@@

Use `/rename` to give sessions descriptive names (`「oauth-migration」`, `「debugging-memory-leak」`) so you can find them later. Treat sessions like branches. Different workstreams can have separate, persistent contexts.

***

## Automate and scale

Once you're effective with one Claude, multiply your output with parallel sessions, headless mode, and fan-out patterns.

Everything so far assumes one human, one Claude, and one conversation. But Claude Code scales horizontally. The techniques in this section show how you can get more done.

### Run headless mode

> **Tip:**
> Use `claude -p "prompt"` in CI, pre-commit hooks, or scripts. Add `--output-format stream-json` for streaming JSON output.

With `claude -p "your prompt"`, you can run Claude headlessly, without an interactive session. Headless mode is how you integrate Claude into CI pipelines, pre-commit hooks, or any automated workflow. The output formats (plain text, JSON, streaming JSON) let you parse results programmatically.

@@CODE_BLOCK_10@@

### Run multiple Claude sessions

> **Tip:**
> Run multiple Claude sessions in parallel to speed up development, run isolated experiments, or start complex workflows.

There are two main ways to run parallel sessions:

* [Claude Desktop](/en/desktop): Manage multiple local sessions visually. Each session gets its own isolated worktree.
* [Claude Code on the web](/en/claude-code-on-the-web): Run on Anthropic's secure cloud infrastructure in isolated VMs.

Beyond parallelizing work, multiple sessions enable quality-focused workflows. A fresh context improves code review since Claude won't be biased toward code it just wrote.

For example, use a Writer/Reviewer pattern:

| Session A (Writer)                                                      | Session B (Reviewer)                                                                                                                                                     |
| ----------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `API エンドポイント向けのレートリミッターを実装してください`                        |                                                                                                                                                                          |
|                                                                         | `@src/middleware/rateLimiter.ts のレートリミッター実装をレビューしてください。エッジケース、レースコンディション、既存のミドルウェアパターンとの一貫性を確認してください。` |
| `これがレビューのフィードバックです: [Session B output]。これらの問題に対処してください。` |                                                                                                                                                                          |

You can do something similar with tests: have one Claude write tests, then another write code to pass them.

### Fan out across files

> **Tip:**
> Loop through tasks calling `claude -p` for each. Use `--allowedTools` to scope permissions for batch operations.

For large migrations or analyses, you can distribute work across many parallel Claude invocations:

<Steps>
  <Step title="Generate a task list">
    Have Claude list all files that need migrating (e.g., `移行が必要な 2,000 個の Python ファイルをすべて列挙して`)
  </Step>

  <Step title="Write a script to loop through the list">
    ```bash  theme={null}
    for file in $(cat files.txt); do
      claude -p "Migrate $file from React to Vue. Return OK or FAIL." \
        --allowedTools "Edit,Bash(git commit:*)"
    done
    ```
  </Step>

  <Step title="Test on a few files, then run at scale">
    Refine your prompt based on what goes wrong with the first 2-3 files, then run on the full set. The `--allowedTools` flag restricts what Claude can do, which matters when you're running unattended.
  </Step>
</Steps>

You can also integrate Claude into existing data/processing pipelines:

@@CODE_BLOCK_11@@

Use `--verbose` for debugging during development, and turn it off in production.

### Safe Autonomous Mode

Use `claude --dangerously-skip-permissions` to bypass all permission checks and let Claude work uninterrupted. This works well for workflows like fixing lint errors or generating boilerplate code.

> **Warning:**
> Letting Claude run arbitrary commands is risky and can result in data loss, system corruption, or data exfiltration (e.g., via prompt injection attacks). To minimize these risks, use `--dangerously-skip-permissions` in a container without internet access.
> 
> With sandboxing enabled (`/sandbox`), you get similar autonomy with better security. Sandbox defines upfront boundaries rather than bypassing all checks.

***

## Avoid common failure patterns

These are common mistakes. Recognizing them early saves time:

* **The kitchen sink session.** You start with one task, then ask Claude something unrelated, then go back to the first task. Context is full of irrelevant information.
  > **Fix**: `/clear` between unrelated tasks.
* **Correcting over and over.** Claude does something wrong, you correct it, it's still wrong, you correct again. Context is polluted with failed approaches.
  > **Fix**: After two failed corrections, `/clear` とし、学んだことを取り入れてより良い初期プロンプトを書いてください。
* **過剰に指定された CLAUDE.md。** CLAUDE.md が長すぎると、重要なルールがノイズに埋もれて、Claude は半分を無視してしまいます。
  > **対処**: 情け容赦なく削る。指示がなくても Claude がすでに正しくやれていることは、削除するかフックに変換する。
* **信頼先行で検証が抜けるギャップ。** もっともらしい実装を出すが、エッジケースを扱えていない。
  > **対処**: 常に検証手段（テスト、スクリプト、スクリーンショット）を提供する。検証できないなら出荷しない。
* **無限の探索。** 「調査して」とだけ頼むと範囲が定まらず、Claude は何百ものファイルを読み、コンテキストを埋め尽くす。
  > **対処**: 調査の範囲を狭めるか、サブエージェントを使って、探索がメインのコンテキストを消費しないようにする。

***

## 直感を磨く

このガイドのパターンは絶対ではありません。一般にうまく機能する出発点ですが、あらゆる状況で最適とは限りません。

1 つの複雑な問題に深く取り組んでいて履歴が価値を持つときは、コンテキストを蓄積させるべき場合もあります。探索的なタスクなら、計画を省いて Claude に任せた方がよい場合もあります。問題を制約する前に Claude の解釈を見たいから、あえて曖昧なプロンプトがちょうどよい場面もあります。

うまくいったときに何が効いたかに注意を払いましょう。Claude が素晴らしい出力を出したら、自分が何をしたかを観察します。プロンプトの構造、提供したコンテキスト、使っていたモード。Claude が苦戦したら理由を考えます。コンテキストがノイズまみれだった？プロンプトが曖昧すぎた？1 回で処理するには大きすぎるタスクだった？

時間とともに、このガイドでは捉えきれない直感が育ちます。いつ具体的に、いつオープンにするか。いつ計画し、いつ探索するか。いつコンテキストをクリアし、いつ蓄積させるかがわかるようになります。

## 関連リソース

<CardGroup cols={2}>
  <Card title="Claude Code の仕組み" icon="gear" href="/en/how-claude-code-works">
    エージェント的ループ、ツール、コンテキスト管理を理解する
  </Card>

  <Card title="Claude Code を拡張する" icon="puzzle-piece" href="/en/features-overview">
    Skills、Hooks、MCP、サブエージェント、プラグインから選ぶ
  </Card>

  <Card title="一般的なワークフロー" icon="list-check" href="/en/common-workflows">
    デバッグ、テスト、PR などのステップバイステップレシピ
  </Card>

  <Card title="CLAUDE.md" icon="file-lines" href="/en/memory">
    プロジェクトの規約と永続的なコンテキストを保存する
  </Card>
</CardGroup>
