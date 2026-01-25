# doc-fetcher evals (list only)

Minimal eval harness for `skills/doc-fetcher` that checks whether the agent runs the `--list`
command when asked to list sources from state, and avoids running it for unrelated prompts.

## Run

```bash
./evals/doc-fetcher/run.sh
ruby ./evals/doc-fetcher/check.rb
```

## What it checks

- should_trigger=1 -> at least one `anthropic_fetch.rb --list` command observed
- should_trigger=0 -> no `--list` command observed
- rejects `--list` combined with `--all` or `--id`

## Notes

- This is a deterministic, no-write eval. It does not fetch or snapshot anything.
- Next step: add a `--dry-run --id` suite or a local HTTP fixture for full fetch checks.
