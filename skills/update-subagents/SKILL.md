---
name: update-subagents
description: |
  Interactively enable or disable subagents from the CLI. Shows a checklist of all available agents with their current status and lets the user toggle them on or off. Use when the user says "manage agents", "disable agent", "enable agent", "toggle agents", "list agents", or "/update-subagents".
allowed-tools:
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

Scan both directories for `.md` and `.md.disabled` files:

```bash
ls -1 ~/.claude/agents/*.md ~/.claude/agents/*.md.disabled .claude/agents/*.md .claude/agents/*.md.disabled 2>/dev/null
```

For each file, read the `name:` and `description:` from the YAML frontmatter.

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

When the user specifies which agents to toggle:

Use the correct path based on where the agent was discovered:

**To disable:**
```bash
# For user-level agents:
mv ~/.claude/agents/{agent-name}.md ~/.claude/agents/{agent-name}.md.disabled
# For project-level agents:
mv .claude/agents/{agent-name}.md .claude/agents/{agent-name}.md.disabled
```

**To enable:**
```bash
# For user-level agents:
mv ~/.claude/agents/{agent-name}.md.disabled ~/.claude/agents/{agent-name}.md
# For project-level agents:
mv .claude/agents/{agent-name}.md.disabled .claude/agents/{agent-name}.md
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

- Agent names are matched case-insensitively against the `name:` frontmatter field or filename
- Disabled agents are invisible to Claude Code — they won't be auto-invoked or listed
- Re-enabling restores the agent immediately for the next conversation
- Project-level agents (in `.claude/agents/`) affect all contributors — confirm before toggling
