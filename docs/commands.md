# Commands

[Custom slash commands](https://docs.anthropic.com/en/docs/claude-code/slash-commands) for Claude Code. Each `.md` file becomes a `/command` you can run in a session; its contents are the prompt Claude executes, with `$ARGUMENTS` substituted from what you type.

## Install

**Easiest:** install the whole collection as a plugin — see the [root README quick-start](../README.md#quick-start). To copy just these commands manually:

```bash
# All commands (skips README.md)
mkdir -p ~/.claude/commands
cp commands/[a-z]*.md commands/*.js ~/.claude/commands/

# …or just one
cp commands/prepare-PR.md ~/.claude/commands/
```

Use a project's `.claude/commands/` instead of `~/.claude/commands/` to scope them to one repo.

## The commands

| Command | What it does |
|---|---|
| `/fix-issue <number>` | Address a GitHub issue: create a branch named in conventional-commit format including the issue number and title, then work the fix. |
| `/optimize` | Analyse the referenced code for performance issues and suggest optimisations. |
| `/prepare-PR` | Run format / lint / build / typecheck, push to a feature branch (creating one if on `main`), open a PR, and link any related issue. |
| `/ultrathink-task <task>` | Coordinator-agent workflow: orchestrates Architect, Research, Coder, and Tester sub-agents through an "ultrathink" reflection phase to produce a cohesive solution. |
| `/vercel-logs [project] [--since] [--repo]` | Read Vercel deployment logs and open GitHub issues for errors found. |

### Note on `/vercel-logs`

It ships as `vercel-logs.md` plus a Node helper `vercel-logs.js`. The script needs a few npm packages (`commander`, `axios`, `chalk`, `date-fns`) and two environment variables — `VERCEL_TOKEN` and `GITHUB_TOKEN` (optionally `GITHUB_REPO`). No credentials are bundled; you supply your own via the environment.
