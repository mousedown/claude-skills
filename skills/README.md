# Skills

[Agent skills](https://docs.anthropic.com/en/docs/claude-code/skills) for Claude Code — packaged workflows Claude loads on demand when your request matches. Each is a folder with a `SKILL.md`; Claude reads the `description` to decide when to activate it, or you can trigger one explicitly with `/<name>`.

## Install

```bash
# All skills
cp -R skills/* ~/.claude/skills/

# …or just one
cp -R skills/pr-review ~/.claude/skills/
```

Drop them in a project's `.claude/skills/` instead of `~/.claude/skills/` to share with everyone working in that repo. Start a new conversation to pick them up.

## The skills

| Skill | Trigger | What it does |
|---|---|---|
| **pr-review** | `/pr-review`, "review this PR" | Multi-agent PR review that mirrors Claude Code's Code Review pipeline — fans out parallel specialist reviewers, adversarially verifies each finding to kill false positives, then reports deduplicated findings ranked 🔴 Important / 🟡 Nit / 🟣 Pre-existing. `--comment` posts to the PR, `--fix` applies fixes. |
| **update-subagents** | `/update-subagents`, "manage agents" | Enable or disable subagents from the CLI via an interactive checklist (renames `.md` ↔ `.md.disabled`). Pairs with the [`agents/`](../agents) collection. |
| **git** | "commit and push", "push changes" | Stage, commit, and push with a generated conventional-commit message. |
| **autofix-pr** | "autofix pr", "fix pr issues" | Reviews PR comments, fixes valid critical/high-severity issues, and replies to every comment. |
| **fix-pr-comments** | `/fix-pr-comments`, "action pr comments" | Investigates each PR comment, presents a plan, gets approval, implements fixes, then replies and resolves. |
| **update-pr-description** | `/update-pr-description`, "update pr" | Analyses the whole branch diff and rewrites the PR title and body, preserving user-added content (images, HTML). |
| **prd-to-issues** | "convert PRD to issues" | Breaks a PRD into independently-grabbable GitHub issues using tracer-bullet vertical slices. |
| **write-a-prd** | "write a PRD" | Builds a PRD through user interview, codebase exploration, and module design, then submits it as a GitHub issue. |
| **ralphy** | "ralphy", "PROMPT.md" | Creates or refines a `PROMPT.md` for the [ralph-orchestrator](https://github.com/mikeyobrien/ralph-orchestrator) system. |

## Writing your own

A skill is just a directory with a `SKILL.md`: YAML frontmatter (`name`, `description`, optional `allowed-tools`) followed by the instructions Claude should follow. Keep the `description` specific — it's how Claude decides when to reach for the skill.
