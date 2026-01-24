---
name: brave-search
description: Brave Search API で Web 検索とコンテンツ抽出。ドキュメント、事実、Web コンテンツの検索に使用。軽量でブラウザ不要。
---

# Brave Search

Brave Search を使ったヘッドレス Web 検索とコンテンツ抽出。ブラウザ不要。

## セットアップ

初回使用前に実行：

```bash
cd ~/Work/agent-kit/skills/brave-search
npm ci
```

環境変数が必要: `BRAVE_API_KEY`

1Password から取得する場合：
```bash
export BRAVE_API_KEY=$(op read "op://Personal/Brave Search/credential")
```

## 検索

```bash
./search.js "クエリ"                    # 基本検索（5件）
./search.js "クエリ" -n 10              # 件数指定
./search.js "クエリ" --content          # ページコンテンツを Markdown で含める
./search.js "クエリ" -n 3 --content     # 組み合わせ
```

## ページコンテンツ抽出

```bash
./content.js https://example.com/article
```

URL を取得し、読みやすいコンテンツを Markdown で抽出。

## 出力形式

```
--- Result 1 ---
Title: ページタイトル
Link: https://example.com/page
Snippet: 検索結果からの説明
Content: (--content フラグ使用時)
  ページから抽出した Markdown コンテンツ...

--- Result 2 ---
...
```

## 使用シーン

- ドキュメントや API リファレンスの検索
- 事実や最新情報の調査
- 特定 URL からのコンテンツ取得
- ブラウザなしで Web 検索が必要なタスク
