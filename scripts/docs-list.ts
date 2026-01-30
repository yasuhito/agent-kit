#!/usr/bin/env tsx

import { readdirSync, readFileSync, statSync } from 'node:fs';
import { dirname, join, relative, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const EXCLUDED_DIRS = new Set(['archive', 'research']);

function isDirectory(path: string): boolean {
  try {
    return statSync(path).isDirectory();
  } catch {
    return false;
  }
}

function resolveDocsDirFrom(startPath: string | undefined): string | null {
  if (!startPath) {
    return null;
  }

  let current = resolve(startPath);
  try {
    if (statSync(current).isFile()) {
      current = dirname(current);
    }
  } catch {
    return null;
  }

  while (true) {
    const docsDir = join(current, 'docs');
    if (isDirectory(docsDir)) {
      return docsDir;
    }
    const parent = dirname(current);
    if (parent === current) {
      return null;
    }
    current = parent;
  }
}

function resolveDocsDir(): string | null {
  const candidates = [process.argv[0], process.argv[1], process.execPath, process.cwd()];

  try {
    candidates.push(fileURLToPath(import.meta.url));
  } catch {
    // ignore bunfs/meta failures
  }

  for (const candidate of candidates) {
    const resolved = resolveDocsDirFrom(candidate);
    if (resolved) {
      return resolved;
    }
  }

  return null;
}

function compactStrings(values: unknown[]): string[] {
  const result: string[] = [];
  for (const value of values) {
    if (value === null || value === undefined) {
      continue;
    }
    const normalized = String(value).trim();
    if (normalized.length > 0) {
      result.push(normalized);
    }
  }
  return result;
}

function walkMarkdownFiles(dir: string, base: string = dir): string[] {
  const entries = readdirSync(dir, { withFileTypes: true });
  const files: string[] = [];
  for (const entry of entries) {
    if (entry.name.startsWith('.')) {
      continue;
    }
    const fullPath = join(dir, entry.name);
    if (entry.isDirectory()) {
      if (EXCLUDED_DIRS.has(entry.name)) {
        continue;
      }
      files.push(...walkMarkdownFiles(fullPath, base));
    } else if (entry.isFile() && entry.name.endsWith('.md')) {
      files.push(relative(base, fullPath));
    }
  }
  return files.sort((a, b) => a.localeCompare(b));
}

function extractMetadata(fullPath: string): {
  summary: string | null;
  readWhen: string[];
  error?: string;
} {
  const content = readFileSync(fullPath, 'utf8');

  if (!content.startsWith('---')) {
    return { summary: null, readWhen: [], error: 'missing front matter' };
  }

  const endIndex = content.indexOf('\n---', 3);
  if (endIndex === -1) {
    return { summary: null, readWhen: [], error: 'unterminated front matter' };
  }

  const frontMatter = content.slice(3, endIndex).trim();
  const lines = frontMatter.split('\n');

  let summaryLine: string | null = null;
  const readWhen: string[] = [];
  let collectingField: 'read_when' | null = null;

  for (const rawLine of lines) {
    const line = rawLine.trim();

    if (line.startsWith('summary:')) {
      summaryLine = line;
      collectingField = null;
      continue;
    }

    if (line.startsWith('read_when:')) {
      collectingField = 'read_when';
      const inline = line.slice('read_when:'.length).trim();
      if (inline.startsWith('[') && inline.endsWith(']')) {
        try {
          const parsed = JSON.parse(inline.replace(/'/g, '"')) as unknown;
          if (Array.isArray(parsed)) {
            readWhen.push(...compactStrings(parsed));
          }
        } catch {
          // ignore malformed inline arrays
        }
      }
      continue;
    }

    if (collectingField === 'read_when') {
      if (line.startsWith('- ')) {
        const hint = line.slice(2).trim();
        if (hint) {
          readWhen.push(hint);
        }
      } else if (line === '') {
      } else {
        collectingField = null;
      }
    }
  }

  if (!summaryLine) {
    return { summary: null, readWhen, error: 'summary key missing' };
  }

  const summaryValue = summaryLine.slice('summary:'.length).trim();
  const normalized = summaryValue
    .replace(/^['"]|['"]$/g, '')
    .replace(/\s+/g, ' ')
    .trim();

  if (!normalized) {
    return { summary: null, readWhen, error: 'summary is empty' };
  }

  return { summary: normalized, readWhen };
}

const docsDir = resolveDocsDir();

if (!docsDir) {
  console.error('docs-list: docs directory not found. Run from repo root.');
  process.exit(1);
}

console.log('Listing all markdown files in docs folder:');

const markdownFiles = walkMarkdownFiles(docsDir);

for (const relativePath of markdownFiles) {
  const fullPath = join(docsDir, relativePath);
  const { summary, readWhen, error } = extractMetadata(fullPath);
  if (summary) {
    console.log(`${relativePath} - ${summary}`);
    if (readWhen.length > 0) {
      console.log(`  Read when: ${readWhen.join('; ')}`);
    }
  } else {
    const reason = error ? ` - [${error}]` : '';
    console.log(`${relativePath}${reason}`);
  }
}

console.log(
  '\nReminder: keep docs up to date as behavior changes. When your task matches any "Read when" hint above (React hooks, cache directives, database work, tests, etc.), read that doc before coding, and suggest new coverage when it is missing.'
);
