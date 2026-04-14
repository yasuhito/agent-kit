---
summary: 'GHSA セキュリティアドバイザリの triage を最後まで進める（fix、gate、GHSA patch、publish 準備）'
read_when:
  - GHSA triage を議論後に一気通貫で完了したい時
argument-hint: '<ghsa-or-url?>'
---
# /sectriage

議論後に使う。「これを GitHub に gh で反映して」または `/sectriage` と言われたら、remote write の同意があるものとみなし、`gh api` で GHSA を patch して確認する。

## 意図

デフォルト意図: fix を `main` に直接着地させる（commit + push。PR なし）、`CHANGELOG.md` を更新し、GHSA は「あとで publish するだけ」の状態にする。明示的に求められない限り、別 PR / private PR ワークフローにはしない。

## Invocation Format（貼り付け用、任意）

最小入力を優先。`ghsa`（または URL）だけ渡された場合、残りは repo と tags から導出し、曖昧な場合だけ確認する。

- `repo`: `owner/name`（任意。省略時は `git remote` から導出）
- `ghsa`: `GHSA-....`（または advisory URL）
- `severity`: `low|medium|high|critical`
- `cvss`: 完全な vector string（任意。ただし設定/復元するなら含める）
- `affected`: 人間向け範囲行（例: `<= 2026.2.13`）
- `vuln_range`: GitHub structured `vulnerable_version_range`（例: `<=2026.2.13`）
- `patched_versions`: 修正版の予定バージョン（通常は次に ship する版。changelog / release 準備から導出）
- `package`: 通常は npm package 名
- `credits`: 報告者ハンドル（例: `@akhmittra`）
- `fix_commits`: fix が merge 済みなら full SHA を 1 個以上
- `summary`: 1 行要約（GHSA id は入れない）
- `description_md`: advisory description の Markdown 全文（「Affected Packages / Versions」節を必ず含める）

## 何をするか（提案ではなく実行）

1. 入力を解釈。`repo` 省略時は `git remote -v` から導出。必要なら URL から GHSA id を抽出。
2. Preflight:
   - `git status --porcelain`（クリーン、または想定済みファイルのみ）
   - `gh api ...security-advisories/<GHSA>` で advisory を取得し、現在の structured fields を表示
   - 既存 fix PR を探す（再利用優先、重複 fix を避ける）:
     - advisory に `private_fork.full_name` があれば `gh pr list -R <privateFork> --state open`
     - upstream 側も `gh pr list -R <repo> --search "<GHSA>" --state all`
     - 妥当な fix PR があれば:
       - `gh pr view` / `gh pr diff` でレビュー
       - ローカル branch 切替は避け、`git fetch <remote> <headRef>` → `git cherry-pick <sha>...`
   - 公開済み最新 version を取得:
     - `npm view <pkg> version --userconfig "$(mktemp)"`
     - 問題がまだ `main` に残っているなら、`vulnerable_version_range` が最新公開版を含むよう更新
   - fixed-version rule（「publish ボタンを押すだけ」状態を最優先）:
     - `CHANGELOG.md`（または `package.json`）から次 release version を使う
     - npm publish 前でも `patched_versions` はその予定版にする
3. ローカル検証（必須）:
   - `pnpm check`
   - `pnpm exec vitest run --config vitest.gateway.config.ts`
   - `pnpm test:fast`
4. Changelog:
   - `CHANGELOG.md` に `## Unreleased` + `### Fixes` があることを確認
   - GHSA id は書かない
   - 報告者への thanks を含める
   - 次の npm release で ship されることが分かる文言にする
   - changelog 修正が必要な場合だけ commit
5. Git:
   - ローカルコミットが origin より先行していたら `git pull --rebase` → `git push`
6. 類似 issue の確認（read-only）:
   - 他の `pathToFileURL(` + dynamic `import(` の callsite を列挙
   - obvious な path-join/resolve callsite を列挙
   - 信頼できる escape bug が見つかったら停止して報告（`/sectriage` 中に surprise-fix しない）
7. GHSA patch（remote write。invoke 自体が同意）:
   - `description_md` から `/tmp/ghsa.desc.md` を作る
   - `description_md` には必須:
     - 明示的な versions（最新公開版 + affected ranges）
     - 「Fix Commit(s)」節（full SHA を 1 個以上。未 merge なら `pending`）
     - 「Release Process Note」節（patched version は次の予定版を事前設定済み。npm release 後は advisory を publish するだけ）
   - `/tmp/ghsa.patch.json` を `summary`, `severity`, `description`, `vulnerabilities[]` 付きで作る
     - `vulnerable_version_range` は最新公開 npm version を使う（通常 `<=<npmVersion>`）
     - `patched_versions` は次の予定版を使う
   - `gh api -X PATCH ... --input /tmp/ghsa.patch.json`
   - `cvss` があれば `cvss_vector_string` も patch
8. Verify:
   - advisory を再取得し、`html_url`, `state`, `vulnerabilities`, `cvss`, `updated_at` を表示
   - GHSA link を表示

## 実装メモ（厳守）

- JSON quoting の事故を避ける:
  - `description_md` は `/tmp/ghsa.desc.md` へ
  - JSON は `jq -n --rawfile desc /tmp/ghsa.desc.md ...` で組み立てる
- advisory comment endpoint は REST で無いかもしれない。更新は `description` + structured fields で行う。
- state transition（accept/publish）は UI / Publisher 専用の可能性が高い。明示的に求められない限り触らない。
