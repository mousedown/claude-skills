---
name: update-subagents
description: |
  Interactively enable or disable subagents from the CLI. Shows a checklist of all available agents with their current status and lets the user toggle them on or off. Use when the user says "manage agents", "disable agent", "enable agent", "toggle agents", "list agents", or "/update-subagents".
allowed-tools:
    - Bash(find *)
    - Bash(ls *)
    - Bash(mv *)
    - Bash(cat *)
    - Bash(head *)
    - Read
    - Glob
---

# Manage SubAgents

Interactively list, enable, and disable subagents via the CLI.

## Agent Directories

Agents are discovered from two locations:
- **User-level**: `~/.claude/agents/` (personal, all projects)
- **Project-level**: `.claude/agents/` (shared, this repo)

An agent is **enabled** if its file ends in `.md`. It is **disabled** if renamed to `.md.disabled`.

## Workflow

### 1. Discover all agents

Scan both directories for `.md` and `.md.disabled` files. Use `find`, not a glob — under zsh an unmatched pattern (e.g. no disabled agents yet) aborts the whole command and hides every agent:

```bash
find ~/.claude/agents .claude/agents -maxdepth 1 -type f \( -name '*.md' -o -name '*.md.disabled' \) 2>/dev/null
```

For each file, read the `name:` and `description:` from the YAML frontmatter — and keep its **actual filename**, which you need to toggle it (the filename may differ from `name:`).

### 2. Present the checklist

Display an interactive-style checklist to the user, grouped by scope. Example:

```
## SubAgent Manager

  User agents (~/.claude/agents/)
  ────────────────────────────────────────────────────────────
  [x] ada-devils-advocate                                    [user]
  [x] business-analyst                                       [user]
  [x] code-reviewer                                          [user]
  [x] feature-finisher                                       [user]
  [x] ios-native-expert                                      [user]
  [x] nadia-security-auditor                                 [user]
  [x] ralphy                                                 [user]
  [ ] seo-optimizer                                          [user]

  [x] = enabled, [ ] = disabled
  [project] = shared with all contributors
  [user] = personal, all projects

Which agents would you like to toggle? (e.g. "disable foo, bar" or "enable all")
```

Use `[x]` for enabled agents (`.md` files) and `[ ]` for disabled agents (`.md.disabled` files).

Group agents by scope: project-level first, then user-level. Within each group, sort alphabetically by the agent's `name:` field (from frontmatter) — or filename if frontmatter is missing.

### 3. Apply changes

When the user specifies which agents to toggle, resolve each request to the **actual file discovered in step 1** — match case-insensitively against the agent's `name:` or its filename, then operate on that file's real path. The filename may differ from `name:` (e.g. a file `ba.md` whose frontmatter is `name: business-analyst`), so never rebuild the path from `name:`. Disabling appends `.disabled` to the whole filename (`ba.md` → `ba.md.disabled`).

Use `~/.claude/agents/` for user-level agents and `.claude/agents/` for project-level, matching where the file was found. With `{file}` = the discovered filename:

**To disable:**
```bash
mv ~/.claude/agents/{file} ~/.claude/agents/{file}.disabled
```

**To enable:**
```bash
mv ~/.claude/agents/{file}.disabled ~/.claude/agents/{file}
```

### 4. Confirm

Show the updated checklist after changes are applied:

```
Updated:
  - foo: enabled → disabled
  - bar: enabled → disabled

Current status:
  ...
  [ ] foo                                                    [project]
  ...
  [ ] bar                                                    [project]
  ...
```

## Bulk Operations

Support these shorthand commands:
- `disable all` — disable all agents
- `enable all` — enable all agents
- `disable foo, bar, baz` — disable specific agents by name
- `enable foo` — enable a specific agent by name

## Notes

- Agent names are matched case-insensitively against the `name:` frontmatter field or filename, then toggled by the file's real filename (which may differ from `name:`)
- Disabled agents are invisible to Claude Code — they won't be auto-invoked or listed
- Re-enabling restores the agent immediately for the next conversation
- Project-level agents (in `.claude/agents/`) affect all contributors — confirm before toggling
