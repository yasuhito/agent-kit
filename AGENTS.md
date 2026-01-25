# AGENTS

## Testing

- Cucumber の Then は 1 つの期待だけにする（agent_type と completion は別シナリオ）。
- テストデータは feature の heredoc で渡し、step 実装には埋め込まない。
