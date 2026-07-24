# Claude Skills

A collection of extensions for [Claude Code](https://claude.com/claude-code) — **sub-agents**, **skills**, and **slash commands**, plus a set of terminal **statuslines**. Install everything as a plugin in two commands, or copy just the pieces you want.

## Quick start

### Install as a plugin (recommended)

Run these inside Claude Code:

```
/plugin marketplace add mousedown/claude-skills
/plugin install claude-skills@mousedown
```

That installs all 8 sub-agents, 9 skills, and 5 commands at once — no file copying — and keeps them current with `/plugin marketplace update mousedown`. Plugin skills and commands are namespaced, e.g. `/claude-skills:pr-review`, `/claude-skills:prepare-PR`.

<details><summary>Prefer the terminal? Same thing without opening Claude Code first.</summary>

```bash
claude plugin marketplace add mousedown/claude-skills
claude plugin install claude-skills@mousedown
```
</details>

### Or copy individual files (fork & customize)

Everything is a plain Markdown file — grab only what you want:

```bash
mkdir -p ~/.claude/agents ~/.claude/skills ~/.claude/commands
cp agents/[a-z]*.md ~/.claude/agents/                          # sub-agents
for d in skills/*/; do cp -R "${d%/}" ~/.claude/skills/; done  # skills
cp commands/[a-z]*.md commands/*.js ~/.claude/commands/        # commands
```

Use a project's `.claude/` instead of `~/.claude/` to scope them to one repo. Copied this way, skills and commands keep their short names (`/pr-review`, not `/claude-skills:pr-review`).

### Statuslines

Statuslines are separate from the plugin and install with a one-liner:

```bash
curl -fsSL https://raw.githubusercontent.com/mousedown/claude-skills/main/install.sh | bash -s <theme>
```

See the gallery in **[statuslines/README.md](statuslines/README.md)**.

## What's inside

| | Collection | Count | Details |
|---|---|---|---|
| 🤖 | **Sub-Agents** | 8 | code review, security audit, iOS, SEO, requirements, and more — [docs/agents.md](docs/agents.md) |
| 🧠 | **Skills** | 9 | PR review, PRD authoring, git, PR/issue workflows — [docs/skills.md](docs/skills.md) |
| ⚡ | **Commands** | 5 | `/prepare-PR`, `/ultrathink-task`, `/vercel-logs`, and more — [docs/commands.md](docs/commands.md) |
| 🎨 | **Statuslines** | 26 | terminal statusline themes — [statuslines/README.md](statuslines/README.md) |

## How things are invoked

| Kind | How it runs |
|---|---|
| **Commands** (5) | You type the slash command: `/claude-skills:prepare-PR` |
| **Skills** (9) | Claude runs them automatically when your request matches — or type `/claude-skills:pr-review` to force one |
| **Sub-agents** (8) | Claude delegates automatically — or ask for one by name, e.g. "have the code-reviewer look at this" |

Namespacing like `claude-skills:` applies when installed as a plugin. Copied manually, they use their bare names.

## Repo layout

```
claude-skills/
├── .claude-plugin/   # plugin.json + marketplace.json (the installable plugin)
├── agents/           # 8 sub-agent definitions
├── skills/           # 9 agent skills
├── commands/         # 5 slash commands
├── statuslines/      # 26 statusline themes + install.sh
├── docs/             # per-collection reference (agents, skills, commands)
└── assets/           # shared screenshots
```

## License

[MIT](LICENSE) — free to use, modify, and share.
