Run the following commands to prepare for a PR:

1. **Format check**: `bun run format:check` (if available)
2. **Lint**: `bun run lint` (if available)
3. **Build**: `bun run build` (if available)
4. **Type check**: `bun run typecheck` (if available)

Ensure all commands pass without errors. Once they do, you push to the relevant feature branch (create one if on main) and push, then create the PR.

If this work relates to a GitHub issue:

- Add a comment to close the issue: `Fixes #[issue-number]` (include issue title)
- Update the PR notes to include detail on all changes from the branch, not just the most recent commit.
- Provide the PR link after creation

Note: Include some emojis and some humurous language now and again. Feel free to swear if you can. I don't mind.
