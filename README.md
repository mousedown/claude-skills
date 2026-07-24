# Claude Skills

A monorepo of extensions for [Claude Code](https://claude.com/claude-code) — **statuslines**, **sub-agents**, **skills**, and **slash commands** you can drop into your own setup. Browse a collection, copy what you want, and go.

## Collections

| | Collection | Count | What it is |
|---|---|---|---|
| 🎨 | **[Statuslines](statuslines)** | 26 | Terminal statusline themes, from minimal to powerline to sci-fi. One-line install. |
| 🤖 | **[Sub-Agents](agents)** | 8 | Specialised assistants Claude delegates to — code review, security audit, iOS, SEO, and more. |
| 🧠 | **[Skills](skills)** | 9 | Packaged workflows Claude loads on demand — PR review, PRD authoring, git, and more. |
| ⚡ | **[Commands](commands)** | 5 | Custom slash commands — `/prepare-PR`, `/ultrathink-task`, `/vercel-logs`, and more. |

## Quick start

**Statuslines** install with a one-liner:

```bash
curl -fsSL https://raw.githubusercontent.com/mousedown/claude-skills/main/install.sh | bash -s <theme>
```

See the full gallery and theme names in **[statuslines/README.md](statuslines/README.md)**.

**Sub-agents, skills, and commands** are files you copy into your Claude Code config:

```bash
cp agents/*.md              ~/.claude/agents/     # sub-agents
cp -R skills/*              ~/.claude/skills/     # skills
cp commands/*.md commands/*.js ~/.claude/commands/ # commands
```

Each has its own README with per-item detail and install notes. Use a project's `.claude/` directory instead of `~/.claude/` to scope any of them to a single repo.

## Repo layout

```
claude-skills/
├── statuslines/   # 26 statusline themes + install.sh
├── agents/        # 8 sub-agent definitions
├── skills/        # 9 agent skills
├── commands/      # 5 slash commands
└── assets/        # shared screenshots
```

## License

[MIT](LICENSE) — free to use, modify, and share.
