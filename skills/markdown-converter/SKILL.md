---
name: markdown-converter
description: markitdown でドキュメントやファイルを Markdown に変換。PDF、Word (.docx)、PowerPoint (.pptx)、Excel (.xlsx, .xls)、HTML、CSV、JSON、XML、画像（EXIF/OCR 付き）、音声（文字起こし付き）、ZIP アーカイブ、YouTube URL、EPub を Markdown 形式に変換して LLM 処理やテキスト分析に使用。
---

# Markdown コンバーター

`uvx markitdown` でファイルを Markdown に変換 — インストール不要。

## 基本的な使い方

```bash
# 標準出力に変換
uvx markitdown input.pdf

# ファイルに保存
uvx markitdown input.pdf -o output.md
uvx markitdown input.docx > output.md

# 標準入力から
cat input.pdf | uvx markitdown
```

## 対応フォーマット

- **ドキュメント**: PDF, Word (.docx), PowerPoint (.pptx), Excel (.xlsx, .xls)
- **Web/データ**: HTML, CSV, JSON, XML
- **メディア**: 画像（EXIF + OCR）、音声（EXIF + 文字起こし）
- **その他**: ZIP（内容を反復処理）、YouTube URL、EPub

## オプション

```bash
-o OUTPUT      # 出力ファイル
-x EXTENSION   # ファイル拡張子のヒント（標準入力用）
-m MIME_TYPE   # MIME タイプのヒント
-c CHARSET     # 文字セットのヒント（例: UTF-8）
-d             # Azure Document Intelligence を使用
-e ENDPOINT    # Document Intelligence エンドポイント
--use-plugins  # サードパーティプラグインを有効化
--list-plugins # インストール済みプラグインを表示
```

## 例

```bash
# Word ドキュメントを変換
uvx markitdown report.docx -o report.md

# Excel スプレッドシートを変換
uvx markitdown data.xlsx > data.md

# PowerPoint プレゼンテーションを変換
uvx markitdown slides.pptx -o slides.md

# ファイルタイプヒント付きで変換（標準入力用）
cat document | uvx markitdown -x .pdf > output.md

# Azure Document Intelligence でより良い PDF 抽出
uvx markitdown scan.pdf -d -e "https://your-resource.cognitiveservices.azure.com/"
```

## メモ

- 出力はドキュメント構造を保持: 見出し、テーブル、リスト、リンク
- 初回実行時に依存関係をキャッシュ。以降の実行は高速
- 抽出が不十分な複雑な PDF には `-d` で Azure Document Intelligence を使用
